@isTest
private class ZipLookupServiceTest {

    // Helper method — creates a test Property, not itself a test
    private static Property__c createTestProperty(String zip) {
        Property__c p = new Property__c(
            Name = 'Test Property',
            Status__c = 'Active',
            Bedrooms__c = 7,
            Bathrooms__c = 7,
            Listing_Date__c = Date.today(),
            Price__c = 5000000,
            Listing_Agent__c = UserInfo.getUserId(),
            Zip__c = zip
        );
        insert p;
        return p;
    }

    @isTest
    static void testEnrichSuccess() {
        Property__c p = createTestProperty('110050');

        Test.setMock(HttpCalloutMock.class, new PostalApiMockSuccess());

        Test.startTest();
        ZipLookupService.enrichPropertyZip(p.Id);
        Test.stopTest(); // forces the @future job to run synchronously here

        Property__c updated = [SELECT City__c, State__c FROM Property__c WHERE Id = :p.Id];
        System.assertEquals('Saket', updated.City__c, 'City should be populated after successful callout');
        System.assertEquals('Delhi', updated.State__c, 'State should be populated after successful callout');
    }

    @isTest
    static void testEnrichFailure() {
        Property__c p = createTestProperty('110050');

        Test.setMock(HttpCalloutMock.class, new PostalApiMockFailure());

        Test.startTest();
        ZipLookupService.enrichPropertyZip(p.Id);
        Test.stopTest();

        Property__c updated = [SELECT City__c, State__c FROM Property__c WHERE Id = :p.Id];
        System.assertEquals(null, updated.City__c, 'City should remain blank on failure');

        List<Audit__c> logs = [SELECT Id, HTTP_Status__c, Source_Id__c FROM Audit__c WHERE Source_Id__c = :p.Id];
        System.assertEquals(1, logs.size(), 'An Audit record should be created on failure');
        System.assertEquals('500', logs[0].HTTP_Status__c, 'Audit should capture the failing status code');
    }

    @isTest
    static void testEnrichBlankZip() {
        Property__c p = createTestProperty(null); // no zip set at all

        Test.startTest();
        ZipLookupService.enrichPropertyZip(p.Id);
        Test.stopTest();

        Property__c updated = [SELECT City__c FROM Property__c WHERE Id = :p.Id];
        System.assertEquals(null, updated.City__c, 'No callout should happen, City stays blank');

        List<Audit__c> logs = [SELECT Id FROM Audit__c WHERE Source_Id__c = :p.Id];
        System.assertEquals(0, logs.size(), 'No callout attempted means no Audit log either');
    }
}