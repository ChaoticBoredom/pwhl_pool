require "rails_helper"

RSpec.describe Draft, type: :model do
  let(:pool) { create(:pool, pool_type: :draft) }

  subject(:draft) { build(:draft, pool: pool) }

  it { is_expected.to belong_to(:pool) }
  it { is_expected.to have_many(:draft_picks).class_name("Draft::Pick").dependent(:destroy) }
  it { is_expected.to have_many(:draft_roster_slots).class_name("Draft::RosterSlot").dependent(:destroy) }

  it do
    is_expected.to define_enum_for(:state).
      with_values(pending: 0, scheduled: 100, in_progress: 200, paused: 300, completed: 999).
      backed_by_column_of_type(:integer)
  end

  it do
    is_expected.to define_enum_for(:pick_order_strategy).
      with_values(snake: 100, fixed: 200).
      backed_by_column_of_type(:integer)
  end

  it "is invalid when the pool is not a draft-type pool" do
    pool = create(:pool, pool_type: :box_select)
    draft = build(:draft, pool: pool)

    expect(draft).to_not be_valid
  end

  describe "current_pick_number" do
    [:pending, :scheduled].each do |state|
      context "when #{state}" do
        subject { build(:draft, pool: pool, state: state) }

        it { is_expected.to validate_numericality_of(:current_pick_number).is_equal_to(0) }
      end
    end

    [:in_progress, :paused, :completed].each do |state|
      context "when #{state}" do
        subject { build(:draft, pool: pool, state: state) }

        it { is_expected.to validate_numericality_of(:current_pick_number).is_greater_than(0) }
      end
    end
  end

  describe "team_order" do
    def team_order_errors(state, order)
      draft = build(:draft, pool: pool, state: state, team_order: order)
      draft.valid?

      draft.errors[:team_order]
    end

    context "when the pool has no teams" do
      [:pending, :scheduled, :in_progress, :paused, :completed].each do |state|
        it "accepts an empty order when #{state}" do
          expect(team_order_errors(state, [])).to be_empty
        end
      end
    end

    context "when the pool has teams" do
      let!(:team_one) { create(:pool_team, pool: pool) }
      let!(:team_two) { create(:pool_team, pool: pool) }
      let(:outsider) { create(:pool_team, pool: create(:pool, pool_type: :draft)) }

      [:pending, :scheduled, :in_progress, :paused, :completed].each do |state|
        context "when #{state}" do
          it "accepts every pool team" do
            expect(team_order_errors(state, [team_one.id, team_two.id])).to be_empty
          end

          it "accepts every pool team in reverse order" do
            expect(team_order_errors(state, [team_two.id, team_one.id])).to be_empty
          end

          it "rejects a duplicated team" do
            expect(team_order_errors(state, [team_one.id, team_two.id, team_one.id])).
              to eq(["must not contain duplicates"])
          end

          it "rejects a team from another pool" do
            expect(team_order_errors(state, [team_one.id, team_two.id, outsider.id])).
              to eq(["must only include teams in the pool"])
          end
        end
      end

      [:pending, :scheduled].each do |state|
        context "before the draft starts (#{state})" do
          it "accepts an empty order" do
            expect(team_order_errors(state, [])).to be_empty
          end

          it "accepts a subset of the pool teams" do
            expect(team_order_errors(state, [team_two.id])).to be_empty
          end
        end
      end

      [:in_progress, :paused, :completed].each do |state|
        context "once the draft has started (#{state})" do
          it "rejects an empty order" do
            expect(team_order_errors(state, [])).to eq(["must include every team in the pool"])
          end

          it "rejects an order missing a pool team" do
            expect(team_order_errors(state, [team_two.id])).to eq(["must include every team in the pool"])
          end
        end
      end
    end
  end

  describe "start_at" do
    context "when transitioning to 'scheduled'" do
      around { |ex| freeze_time(&ex) }

      context "with a new draft" do
        before(:each) { draft.state = :scheduled }

        it "is valid with a start_at far into the future" do
          draft.start_at = 1.hour.from_now

          expect(draft).to be_valid
        end

        it "is valid with a start_at exactly matching the lead time" do
          draft.start_at = 10.minutes.from_now

          expect(draft).to be_valid
        end

        it "is invalid with a start_at just inside the minimum lead time" do
          draft.start_at = 9.minutes.from_now

          expect(draft).to_not be_valid
        end

        it "is invalid with a start_at in the past" do
          draft.start_at = 1.minute.ago

          expect(draft).to_not be_valid
        end

        it "returns a error stating the minimum lead time" do
          draft.start_at = 5.minutes.from_now
          draft.valid?

          expect(draft.errors[:start_at]).to eq(["must be at least 10 minutes from now"])
        end
      end

      context "when a pending draft has a start_at within the lead time" do
        subject(:draft) { create(:draft, pool: pool, state: :pending, start_at: 5.minutes.from_now) }

        it "is valid" do
          expect(draft).to be_valid
        end

        it "cannot be scheduled until the start_at is outside the lead time" do
          draft.state = :scheduled

          expect(draft).to_not be_valid
        end

        it "can be scheduled once start_at is moved out" do
          draft.state = :scheduled
          draft.start_at = 15.minutes.from_now

          expect(draft).to be_valid
        end
      end
    end

    context "when already scheduled" do
      subject(:draft) { create(:draft, pool: pool, state: :scheduled, start_at: 1.hour.from_now) }

      it "is invalid when start_at is moved to inside the lead window" do
        draft.start_at = 5.minutes.from_now

        expect(draft).to_not be_valid
      end

      it "is valid when start_at is moved and stays outside the lead window" do
        draft.start_at = 3.hours.from_now

        expect(draft).to be_valid
      end

      it "stays valid when an unrelated attribute changes after the start_at has passed" do
        travel_to(2.hours.from_now) do
          draft.pick_order_strategy = :fixed

          expect(draft).to be_valid
        end
      end

      it "is valid when moved to in_progress at the start time" do
        travel_to(draft.start_at) do
          draft.state = :in_progress
          draft.current_pick_number = 1

          expect(draft).to be_valid
        end
      end

      it "is valid when moved back to pending inside the lead time" do
        travel_to(draft.start_at - 5.minutes) do
          draft.state = :pending

          expect(draft).to be_valid
        end
      end
    end
  end

  describe "#not_started?" do
    [
      [:pending, true],
      [:scheduled, true],
      [:in_progress, false],
      [:paused, false],
      [:completed, false],
    ].each do |state, expected|
      it "is #{expected} when #{state}" do
        draft.state = state

        expect(draft.not_started?).to be(expected)
      end
    end
  end

  describe "#started?" do
    [
      [:pending, false],
      [:scheduled, false],
      [:in_progress, true],
      [:paused, true],
      [:completed, true],
    ].each do |state, expected|
      it "is #{expected} when #{state}" do
        draft.state = state

        expect(draft.started?).to be(expected)
      end
    end
  end
end
