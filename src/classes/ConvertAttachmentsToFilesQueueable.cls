/**
 * Designed to be invoked within a trigger or some other scenario where you
 * need exactly one batch of records (up to 200 records) to be converted to Files.
 *
 * Actual conversion for the execution is delegated to ConvertAttachmentsToFilesService.
 */
public with sharing class ConvertAttachmentsToFilesQueueable implements Queueable {

    private ConvertAttachmentsToFilesOptions options { get; set; }

    private Set<ID> attachmentIds { get; set; }

    // if context user is a community user then we
    // need to pass on the network id to assign to ContentVersion
    private ID networkId { get; set; }

    public ConvertAttachmentsToFilesQueueable( Set<ID> attachmentIds ) {
        this( attachmentIds, new ConvertAttachmentsToFilesOptions(), Network.getNetworkId() );
    }

    public ConvertAttachmentsToFilesQueueable( Set<ID> attachmentIds, ConvertAttachmentsToFilesOptions options ) {
        this( attachmentIds, options, Network.getNetworkId() );
    }

    public ConvertAttachmentsToFilesQueueable( Set<ID> attachmentIds, ConvertAttachmentsToFilesOptions options, ID networkId ) {
        this.attachmentIds = attachmentIds;
        this.options = options;
        this.networkId = networkId;
    }

    public void execute( QueueableContext context ) {

        System.debug( '[ConvertAttachmentsToFilesQueueable.execute] Executing: ' + context );

        List<Attachment> attachments = new List<Attachment>([
            SELECT
                id, parentId, ownerId, name, description, body, isPrivate,
                createdById, createdDate, lastModifiedById, lastModifiedDate
            FROM
                Attachment
            WHERE
                id IN :this.attachmentIds
            ORDER BY
                parentId
        ]);

        ConvertAttachmentsToFilesService service = new ConvertAttachmentsToFilesService( this.options, this.networkId );

        List<ConvertAttachmentsToFilesService.ConversionResult> results = service.convert( attachments );

        System.debug( '[ConvertAttachmentsToFilesQueueable.execute] Conversion results: ' + results );

    }

}