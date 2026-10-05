trigger CatalogImageVersionTrigger on ContentVersion (after insert) {
    CatalogImagePublisher.publishNewVersions(Trigger.new);
}
