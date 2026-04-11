# PWHL Fantasy Hockey API System

## Overview

This is a Rails API-only backend system that ingests and processes data from the PWHL public API, including game schedules, live game updates, player statistics, and team information.

The system exposes a domain-specific API for a fantasy hockey pool application and includes a background processing pipeline that continuously synchronizes live game data while games are in progress.

A minimal React frontend is included to visualize data and support interaction with the API, but the core focus of the project is backend system design and data processing.

---

## Key Features

- Ingests and normalizes external data from the PWHL API (games, teams, player stats)
- Background Sidekiq workers continuously poll and update live game state until completion
- Maintains near real-time synchronization of player statistics during active games
- Exposes RESTful APIs for a fantasy hockey domain model
- Supports querying player performance, game state, and standings data

---

## Architecture

The system is structured as a backend-first application with clear separation of concerns:

### Ingestion Layer
- Sidekiq workers fetch and process external API data
- Live game state is continuously polled and updated until game completion
- Data is normalized before being persisted to the database

### API Layer
- Rails API exposes domain-focused endpoints for fantasy hockey use cases
- Endpoints are designed around application needs rather than raw external API structure
- Consistent response formats for downstream consumption

### Data Layer
- PostgreSQL is used for persistent storage
- Schema is optimized for frequent updates during active games
- Models represent normalized domain entities (players, teams, games, stats)

### Client Layer (Optional)
- React frontend included for visualization and interaction
- Primarily used for testing and validating backend behavior

---

## Design Considerations

- External API data is treated as unreliable and continuously reconciled with internal state
- Live game updates are handled via repeated background processing until completion
- System supports frequent updates to player statistics during active games without data corruption
- API endpoints are structured around domain concepts rather than external data structures
- Clear separation between ingestion logic and API layer ensures maintainability and flexibility
- Design prioritizes predictable API behavior even while underlying data is changing

---

## Client Application (React)

A minimal React frontend is included to interact with the backend API and visualize live fantasy hockey data.

The frontend exists primarily to support testing and interaction with backend functionality, rather than being the primary focus of the project.

---

## Future Improvements

- Event-driven architecture to replace polling-based Sidekiq updates
- WebSocket support for live game updates
- Caching layer for leaderboard and high-traffic queries
- More advanced fantasy scoring engine
- Rate limiting and retry backoff strategies for upstream API stability

---

## Project Goals

This project demonstrates backend API design, external data integration, and real-time background processing for continuously updating datasets.
