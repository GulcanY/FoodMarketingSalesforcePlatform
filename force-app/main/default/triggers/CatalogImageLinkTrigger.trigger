trigger CatalogImageLinkTrigger on ContentDocumentLink (after insert) {
    CatalogImagePublisher.publish(Trigger.new);
}
