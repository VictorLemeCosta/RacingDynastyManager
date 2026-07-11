export class WorldEngine {

    constructor() {

        this.worldState = {
            currentDate: "2026-01-01",
            currentSeason: 2026,
            running: true,

            activeDrivers: [],
            activeTeams: [],
            activeChampionships: [],

            pendingEvents: []
        };

    }

}