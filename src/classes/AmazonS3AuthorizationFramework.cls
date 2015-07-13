public class AmazonS3AuthorizationFramework {
    public String dtKey = System.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    public String fileContentHash {
        get;
        set;
    }

    @testVisible
    private AWSS3_Bucket_Connection__c bucketConnection;

    @testVisible
    private String dateKey = System.now().formatGMT('yyyyMMdd');

    @testVisible
    private String dtKeyEEE = System.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z');

    // variable name is came from AWS terminology
    private String scope {
        get {
            scope = dateKey + '/' + bucketConnection.AWSS3_Bucket__r.Region__c + '/s3/aws4_request';
            return scope;
        }
        private set;
    }

    public String fileName {
        get {
            return fileName;
        }
        set;
    }

    String putObjectCanonicalRequest {
        get {
            return (AmazonS3Constants.HTTP_METHOD_PUT + '\n'
                + '/' + EncodingUtil.urlEncode(this.fileName, AmazonS3Constants.ENCODING_SCHEME_UTF8) + '\n\n'
                + 'date'.toLowerCase() + ':'+ dtKeyEEE.trim() + '\n'//  + dtKey + '\n'//+ Datetime.now().format('EEE, d MMM yyyy HH:mm:ss z') + '\n' //Fri, 24 May 2013 00:00:00 GMT
                + 'host'.toLowerCase() + ':' + (this.bucketConnection.AWSS3_Bucket__r.Name + AmazonS3Constants.AMAZON_S3_URL).trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  this.fileContentHash + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n'
                + 'x-amz-storage-class'.toLowerCase() + ':' + 'REDUCED_REDUNDANCY'.trim() + '\n\n'
                + 'date'.toLowerCase() + ';' + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + ';' + 'x-amz-storage-class'.toLowerCase() + '\n'
                +  this.fileContentHash);
        }
    }

    String getServiceCanonicalRequest {
        get {
            return (AmazonS3Constants.HTTP_METHOD_GET + '\n'
                + '/' + '\n\n'
                + 'host'.toLowerCase() + ':' + 's3.amazonaws.com'.trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  AmazonS3Constants.EMPTY_STRING_HASH + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n\n'
                + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + '\n'
                + AmazonS3Constants.EMPTY_STRING_HASH);
        }
    }

    String getBucketCanonicalRequest {
        get {
            return (AmazonS3Constants.HTTP_METHOD_GET + '\n'
                + '/' + '\n'
                + EncodingUtil.urlEncode('max-keys', AmazonS3Constants.ENCODING_SCHEME_UTF8) + '=' + EncodingUtil.urlEncode('2', AmazonS3Constants.ENCODING_SCHEME_UTF8)
                + '&' + EncodingUtil.urlEncode('prefix', AmazonS3Constants.ENCODING_SCHEME_UTF8) + '=' + EncodingUtil.urlEncode('J', AmazonS3Constants.ENCODING_SCHEME_UTF8)  + '\n'
                + 'host'.toLowerCase() + ':' + (this.bucketConnection.AWSS3_Bucket__r.Name + AmazonS3Constants.AMAZON_S3_URL).trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  AmazonS3Constants.EMPTY_STRING_HASH + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n\n'
                + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + '\n'
                +  AmazonS3Constants.EMPTY_STRING_HASH);
        }
    }

    public AmazonS3AuthorizationFramework(String ConnectionName) {
        this.bucketConnection = [SELECT
                                    AWSS3_Credential__r.Name,
                                    AWSS3_Credential__r.Access_Key_Id__c,
                                    AWSS3_Credential__r.Secret_Access_Key__c,
                                    AWSS3_Bucket__r.Region__c,
                                    AWSS3_Bucket__r.Name
                                 FROM AWSS3_Bucket_Connection__c
                                 WHERE Name = :ConnectionName];
    }

    private String getCanonicalRequest(AmazonS3ServiceOperations operation) {
        if (operation == AmazonS3ServiceOperations.getService) {
            return getServiceCanonicalRequest;
        } else if (operation == AmazonS3ServiceOperations.getBucket) {
            return getBucketCanonicalRequest;
        } else if (operation == AmazonS3ServiceOperations.putObject) {
            return putObjectCanonicalRequest;
        }
        return null;
    }

    private Map<AmazonS3ServiceOperations, String> signedHeaderByOperationName = new Map<AmazonS3ServiceOperations, String> {
        AmazonS3ServiceOperations.getService
            => ',SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=',
        AmazonS3ServiceOperations.getBucket
            => ',SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=',
        AmazonS3ServiceOperations.putObject
            => ',SignedHeaders=date;host;x-amz-content-sha256;x-amz-date;x-amz-storage-class,Signature='
    };

    @testVisible
    private String generateStringToSign(AmazonS3ServiceOperations operation) {
        // Task 2: Create a String to Sign
        System.debug(LoggingLevel.INFO, '\n-------------------------------  Task 2: Create a String to Sign --------------------------------');
        System.debug(LoggingLevel.INFO, 'canonicalRequest:__________________________________________________________\n' + getCanonicalRequest(operation));
        System.debug(LoggingLevel.INFO, '_____________________________________________________________________________');
        String stringToSing = 'AWS4-HMAC-SHA256' + '\n'
                              + dtKey + '\n'
                              + scope + '\n'
                              + EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueof(getCanonicalRequest(operation))));
        System.debug('\n' + stringToSing + '\n');
        return stringToSing;
    }

    @testVisible
    private String calculateSignature(AmazonS3ServiceOperations operation) {
        // Task 3: Calculate Signature
        //signing key = HMAC-SHA256(HMAC-SHA256(HMAC-SHA256(HMAC-SHA256("AWS4" + "<YourSecretAccessKey>","20130524"),"us-east-1"),"s3"),"aws4_request")
        System.debug('\n-------------------------------  Task 3: Calculate Signature --------------------------------');
        Blob dateKey1             = Crypto.generateMac(AmazonS3Constants.GENERATE_MAC_ALGORITHM_NAME, blob.valueOf(dateKey), blob.valueOf('AWS4' + this.bucketConnection.AWSS3_Credential__r.Secret_Access_Key__c));
        Blob dateRegionKey        = Crypto.generateMac(AmazonS3Constants.GENERATE_MAC_ALGORITHM_NAME, blob.valueOf(bucketConnection.AWSS3_Bucket__r.Region__c), dateKey1);
        Blob dateRegionServiceKey = Crypto.generateMac(AmazonS3Constants.GENERATE_MAC_ALGORITHM_NAME, blob.valueOf('s3'), dateRegionKey);
        Blob signingKey           = Crypto.generateMac(AmazonS3Constants.GENERATE_MAC_ALGORITHM_NAME, blob.valueOf('aws4_request'), dateRegionServiceKey);
        String signature = EncodingUtil.convertToHex(Crypto.generateMac(AmazonS3Constants.GENERATE_MAC_ALGORITHM_NAME, blob.valueOf(generateStringToSign(operation)), signingKey));
        System.debug('\n Signature ==> ' + signature);
        return signature;
    }

    public String calculateAuthorizationHeader(AmazonS3ServiceOperations operation) {
        String fullAuthHeader = 'AWS4-HMAC-SHA256 Credential=' + this.bucketConnection.AWSS3_Credential__r.Access_Key_Id__c + '/' + scope
                                + signedHeaderByOperationName.get(operation) + calculateSignature(operation);
        System.debug('\nfullAuthHeader ' + fullAuthHeader);
        return fullAuthHeader;
    }

    public void setRegion(String region) {
        if (this.bucketConnection != null) {
            bucketConnection.AWSS3_Bucket__r.Region__c = region;
        }
    }

}