export class CalendarEngine {

    advanceDay(worldState) {

        const current =
            new Date(worldState.currentDate);

        current.setDate(current.getDate() + 1);

        worldState.currentDate =
            current.toISOString().split('T')[0];

    }

}