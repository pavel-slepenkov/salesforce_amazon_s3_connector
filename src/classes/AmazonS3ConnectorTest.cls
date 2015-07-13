@isTest
public class AmazonS3ConnectorTest {

    // Mock parameters
    public static String mockDate         = '20130524';
    public static String mockDateTime     = '20130524T000000Z';
    public static String mockAccessKey    = 'AKIAIOSFODNN7EXAMPLE';
    public static String mockSecretKey    = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
    public static String mockBucketName   = 'examplebucket';
    public static String mockRegion       = 'us-east-1';


    //@isTest
    //private static void validateAuthHeaderCalculation() {
    //    System.assertEquals('AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7',
    //                        AmazonS3Connector.calculateAuthorizationHeader());
    //}

    //@isTest
    //private static void validateSignatureCalculation() {
    //    System.assertEquals('34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7', AmazonS3Connector.calculateSignature());
    //}

    @isTest(SeeAllData=true)
    private static void validateGetService() {
        AmazonS3Connector connector = new AmazonS3Connector('Root');
        HttpResponse response = connector.getService();
        System.debug(LoggingLevel.DEBUG, response);
    }

    @isTest(SeeAllData=true)
    private static void validateGetBucket() {
        AmazonS3Connector connector = new AmazonS3Connector('Root');
        HttpResponse response = connector.getBucket('logdog');
        System.debug(LoggingLevel.DEBUG, response);
    }

    @isTest
    private static void validateSignatureCalculationForGetBucket() {
        AWS_IAM_UserCredentials__c creds =
            new AWS_IAM_UserCredentials__c(Name = 'Test',
                                           Secret_Access_Key__c = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
                                           Access_Key_Id__c = 'AKIAIOSFODNN7EXAMPLE',
                                           Bucket_Name__c = mockBucketName);
        insert creds;
        AmazonS3Connector connector = new AmazonS3Connector('Test');
        connector.auth.dateKey          = mockDate;
        connector.auth.dtKey            = mockDateTime;
        connector.auth.setRegion(mockRegion);
        System.assertEquals('34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7', connector.auth.calculateSignature(AmazonS3ServiceOperations.getBucket));
    }

    @isTest
    private static void validateSignatureCalculationForPutObject() {
        AWS_IAM_UserCredentials__c creds =
            new AWS_IAM_UserCredentials__c(Name = 'Test',
                                           Secret_Access_Key__c = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
                                           Access_Key_Id__c = 'AKIAIOSFODNN7EXAMPLE',
                                           Bucket_Name__c = mockBucketName);
        insert creds;
        AmazonS3Connector connector = new AmazonS3Connector('Test');
        connector.auth.dateKey          = mockDate;
        connector.auth.dtKey            = mockDateTime;
        connector.auth.dtKeyEEE         = 'Fri, 24 May 2013 00:00:00 GMT';
        connector.auth.fileName         = 'test$file.text';
        connector.auth.setRegion(mockRegion);
        connector.auth.fileContentHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueof('Welcome to Amazon S3.')));
        System.assert(connector.auth.generateStringToSign(AmazonS3ServiceOperations.putObject).contains('9e0e90d9c76de8fa5b200d8c849cd5b8dc7a3be3951ddb7f6a76b4158342019d'));
        System.assertEquals('98ad721746da40c64f1a55b78f14c238d841ea1380cd77a1b5971af0ece108bd', connector.auth.calculateSignature(AmazonS3ServiceOperations.putObject));
    }

}