public with sharing class SlotService {
    
    // Stała długość wizyty dla MVP (30 min)
    private static final Integer SLOT_DURATION_MINUTES = 30;

    /**
     * Metoda generująca sloty dla danego lekarza na określony dzień.
     * Działa w trybie "on-demand" - czyści stare sloty z tego dnia i tworzy nowe.
     */
    public static void generateSlotsForPractitioner(Id practitionerId, Date dayToProcess) {
        // 1. Pobierz definicje dostępności (Availability__c) lekarza na ten dzień
        List<Availability__c> availabilities = [
            SELECT Id, Start__c, End__c, Timezone__c 
            FROM Availability__c 
            WHERE Practitioner__c = :practitionerId
            AND DAY_ONLY(Start__c) = :dayToProcess
        ];

        // 2. Pobierz istniejące wizyty, aby wykryć kolizje
        List<Appointment__c> existingAppointments = [
            SELECT Start__c, End__c 
            FROM Appointment__c 
            WHERE Practitioner__c = :practitionerId 
            AND DAY_ONLY(Start__c) = :dayToProcess
            AND Status__c != 'Cancelled'
        ];

        List<Slot__c> newSlots = new List<Slot__c>();

        // 3. Główna pętla generowania
        for (Availability__c av : availabilities) {
            DateTime cursor = av.Start__c;
            DateTime endTime = av.End__c;

            // Pętla while generująca sloty co 30 minut
            while (cursor.addMinutes(SLOT_DURATION_MINUTES) <= endTime) {
                DateTime slotEnd = cursor.addMinutes(SLOT_DURATION_MINUTES);
                
                // Sprawdź kolizję z wizytami
                if (!isColliding(cursor, slotEnd, existingAppointments)) {
                    newSlots.add(new Slot__c(
                        Practitioner__c = practitionerId,
                        Availability__c = av.Id,
                        Start__c = cursor,
                        End__c = slotEnd,
                        IsBlocked__c = false,
                        Timezone__c = av.Timezone__c
                    ));
                }
                // Przesuń kursor o 30 minut
                cursor = cursor.addMinutes(SLOT_DURATION_MINUTES);
            }
        }

        // 4. Wyczyść stare sloty (re-generacja) i wstaw nowe
        // Usuwamy tylko sloty z tego konkretnego dnia dla tego lekarza
        delete [SELECT Id FROM Slot__c WHERE Practitioner__c = :practitionerId AND DAY_ONLY(Start__c) = :dayToProcess];
        
        if (!newSlots.isEmpty()) {
            insert newSlots;
        }
    }

    // Pomocnicza metoda sprawdzająca czy przedział czasu nakłada się na istniejącą wizytę
    private static Boolean isColliding(DateTime startT, DateTime endT, List<Appointment__c> appointments) {
        for (Appointment__c appt : appointments) {
            // Logika kolizji: (StartA < EndB) and (EndA > StartB)
            if ((startT < appt.End__c) && (endT > appt.Start__c)) {
                return true;
            }
        }
        return false;
    }
}