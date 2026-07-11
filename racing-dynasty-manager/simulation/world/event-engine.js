export class EventEngine {

    addEvent(worldState, event) {

        worldState.pendingEvents.push(event);

    }

    processEvents(worldState) {

        // futuro

    }

}