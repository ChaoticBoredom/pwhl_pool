require "rails_helper"

RSpec.describe "PoolBoxes", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { auth_headers_for(user) }
  let(:pool) { create(:pool, league: create(:league, :pwhl)) }
  let(:season_id) { pool.display_season_id }

  describe "GET /pools/:pool_id/boxes" do
    subject(:get_index) { get "/api/pools/#{pool.id}/pool_boxes", headers: auth_headers }

    context "when unauthenticated" do
      it "returns 401" do
        get "/api/pools/#{pool.id}/pool_boxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no boxes" do
      it "returns an empty boxes array" do
        get_index
        expect(response.parsed_body["boxes"]).to eq([])
      end

      it "returns pending_trades as false" do
        get_index
        expect(response.parsed_body["pending_trades"]).to be(false)
      end
    end

    context "with boxes and players" do
      let(:player_a) { create(:pwhl_skater, league: pool.league) }
      let(:player_b) { create(:pwhl_skater, league: pool.league) }
      let!(:box) { create(:pool_box, pool: pool, league_player_ids: [player_a.id, player_b.id]) }

      before do
        allow(PlayerRecordQuery).to receive(:new).and_return(
          instance_double(PlayerRecordQuery, records: {}),
        )
        allow_any_instance_of(PlayerScoringService).to receive(:raw_player_summaries).and_return(
          player_a.id => { scores: { today: 1.0, yesterday: 2.0, week_to_date: 3.0, month_to_date: 4.0, season_to_date: 5.0 } },
          player_b.id => { scores: { today: 0.0, yesterday: 0.0, week_to_date: 0.0, month_to_date: 0.0, season_to_date: 10.0 } },
        )
      end

      it "returns 200" do
        get_index
        expect(response).to have_http_status(:ok)
      end

      it "initialises PlayerRecordQuery with players: and season_id:" do
        expect(PlayerRecordQuery).to receive(:new).with(
          players: match_array([player_a, player_b]),
          season_id: season_id,
        ).and_return(instance_double(PlayerRecordQuery, records: {}))
        get_index
      end

      [
        ["id", :id],
        ["name", :name],
        ["order", :position],
      ].each do |field, expected|
        it "renders box #{field}" do
          get_index
          expect(response.parsed_body["boxes"].first[field]).to eq(box[expected])
        end
      end

      [
        ["today", 1.0],
        ["yesterday", 2.0],
        ["week_to_date", 3.0],
        ["month_to_date", 4.0],
        ["season_to_date", 5.0],
      ].each do |window, value|
        it "renders #{window} score for each player" do
          get_index
          scores = response.parsed_body["boxes"].first["players"].
            find { |p| p["id"] == player_a.id }["scores"]
          expect(scores[window]).to eq(value)
        end
      end

      context "selection via current user fallback" do
        context "when the current user has a pool team" do
          let!(:pool_team) { create(:pool_team, pool: pool, owner: user) }

          it "marks a player on the current team as selected" do
            create(:pool_team_player, pool_team: pool_team, league_player: player_a)
            get_index
            players = response.parsed_body["boxes"].first["players"]
            expect(players.find { |p| p["id"] == player_a.id }["selected"]).to be(true)
          end

          it "marks a player not on the current team as not selected" do
            get_index
            players = response.parsed_body["boxes"].first["players"]
            expect(players.find { |p| p["id"] == player_a.id }["selected"]).to be(false)
          end

          it "returns pending_trades true when team has pending requests" do
            create(:trade_request, :add, :pending, pool_team: pool_team, league_player: player_a)
            get_index
            expect(response.parsed_body["pending_trades"]).to be(true)
          end

          it "returns pending_trades false when team has no pending requests" do
            get_index
            expect(response.parsed_body["pending_trades"]).to be(false)
          end
        end

        context "when the current user has no pool team" do
          it "marks all players as not selected" do
            get_index
            players = response.parsed_body["boxes"].first["players"]
            expect(players.map { |p| p["selected"] }).to all(be(false))
          end

          it "returns pending_trades as false" do
            get_index
            expect(response.parsed_body["pending_trades"]).to be(false)
          end
        end
      end

      context "selection via pool_team_id param" do
        let(:other_user) { create(:user) }
        let!(:pool_team) { create(:pool_team, pool: pool, owner: other_user) }

        subject(:get_index_with_team) do
          get "/api/pools/#{pool.id}/pool_boxes",
            params: { pool_team_id: pool_team.id },
            headers: auth_headers
        end

        it "marks a player on the specified team as selected" do
          create(:pool_team_player, pool_team: pool_team, league_player: player_a)
          get_index_with_team
          players = response.parsed_body["boxes"].first["players"]
          expect(players.find { |p| p["id"] == player_a.id }["selected"]).to be(true)
        end

        it "does not use the current user's team for selection" do
          create(:pool_team, pool: pool, owner: user).tap do |current_users_team|
            create(:pool_team_player, pool_team: current_users_team, league_player: player_b)
          end
          create(:pool_team_player, pool_team: pool_team, league_player: player_a)
          get_index_with_team
          players = response.parsed_body["boxes"].first["players"]
          expect(players.find { |p| p["id"] == player_b.id }["selected"]).to be(false)
          expect(players.find { |p| p["id"] == player_a.id }["selected"]).to be(true)
        end

        it "returns pending_trades scoped to the specified team" do
          create(:trade_request, :add, :pending, pool_team: pool_team, league_player: player_a)
          get_index_with_team
          expect(response.parsed_body["pending_trades"]).to be(true)
        end
      end

      context "with an inactive box" do
        let!(:inactive_box) do
          create(:pool_box, pool: pool, league_player_ids: [player_a.id], active: false)
        end

        it "does not return inactive boxes" do
          get_index
          box_names = response.parsed_body["boxes"].map { |b| b["name"] }
          expect(box_names).to_not include(inactive_box.name)
        end
      end
    end
  end
end
