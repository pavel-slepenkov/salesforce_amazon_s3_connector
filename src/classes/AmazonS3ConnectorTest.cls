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
        AmazonS3Connector connector = new AmazonS3Connector('logdog_Root');
        HttpResponse response = connector.getService();
        System.debug(LoggingLevel.DEBUG, response);
    }

    @isTest(SeeAllData=true)
    private static void validateGetBucket() {
        AmazonS3Connector connector = new AmazonS3Connector('logdog_Root');
        HttpResponse response = connector.getBucket('logdog');
        System.debug(LoggingLevel.DEBUG, response);
    }

    private static void initEnv() {
        AWS_IAM_UserCredentials__c creds =
            new AWS_IAM_UserCredentials__c(Name = 'Test',
                                           Secret_Access_Key__c = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
                                           Access_Key_Id__c = 'AKIAIOSFODNN7EXAMPLE');
        insert creds;
        AWSS3_Bucket__c bucket = new AWSS3_Bucket__c(
            name = mockBucketName,
            Region__c = mockRegion
        );
        insert bucket;

        AWSS3_Bucket_Connection__c connection = new AWSS3_Bucket_Connection__c(
            Name = 'Test',
            AWSS3_Bucket__c = bucket.Id,
            AWSS3_Credential__c = creds.Id
        );
        insert connection;
    }

    @isTest
    private static void validateSignatureCalculationForGetBucket() {
        initEnv();
        AmazonS3Connector connector = new AmazonS3Connector('Test');
        connector.auth.dateKey          = mockDate;
        connector.auth.dtKey            = mockDateTime;
        connector.auth.setRegion(mockRegion);
        System.assertEquals('34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7', connector.auth.calculateSignature(AmazonS3ServiceOperations.getBucket));
    }

    @isTest
    private static void validateSignatureCalculationForPutObject() {
        initEnv();
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

    @isTest
    private static void validateSignatureCalculationForGetObject() {

        // String to sign:
        //AWS4-HMAC-SHA256
        //20130524T000000Z
        //20130524/us-east-1/s3/aws4_request
        //7344ae5b7ee6c3e7e6b0fe0640412a37625d1fbfff95c48bbb2dc43964946972


        //f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41

        initEnv();
        AmazonS3Connector connector = new AmazonS3Connector('Test');
        connector.auth.dateKey          = mockDate;
        connector.auth.dtKey            = mockDateTime;
        connector.auth.dtKeyEEE         = 'Fri, 24 May 2013 00:00:00 GMT';
        connector.auth.fileName         = 'test.txt';
        connector.auth.setRegion(mockRegion);
        connector.auth.fileContentHash = AmazonS3Constants.EMPTY_STRING_HASH;
        System.assert(connector.auth.generateStringToSign(AmazonS3ServiceOperations.getObject).contains('7344ae5b7ee6c3e7e6b0fe0640412a37625d1fbfff95c48bbb2dc43964946972'));
        System.assertEquals('f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41', connector.auth.calculateSignature(AmazonS3ServiceOperations.getObject));

    }


}