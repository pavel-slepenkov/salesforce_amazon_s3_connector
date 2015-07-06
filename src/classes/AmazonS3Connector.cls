
public class AmazonS3Connector {

    private String emptyStringHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    @testVisible
    private sfl__AWS_IAM_UserCredintials__c currentUserCreds;
    @testVisible
    private String dateKey          = System.now().formatGMT('yyyyMMdd');
    @testVisible
    private String dtKey            = System.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    @testVisible
    private String dtKeyEEE         = System.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z');
    @testVisible
    private String bucketName       = 'logdog';
    @testVisible
    private String region           = 'eu-west-1';
    private String protocol = 'https://';

    private String scope {
        get {
            scope = dateKey + '/' + region + '/s3/aws4_request';
            return scope;
        }
        private set;
    }

    @testVisible
    private String fileName {
        get {
            return fileName;
        }
        set;
    }

    @testVisible
    String fileContentHash {
        get;
        set;
    }

    String putObjectCanonicalRequest {
        get {
            return ('PUT' + '\n'
                + '/' + EncodingUtil.urlEncode(this.fileName, 'UTF-8') + '\n\n'
                + 'date'.toLowerCase() + ':'+ dtKeyEEE.trim() + '\n'//  + dtKey + '\n'//+ Datetime.now().format('EEE, d MMM yyyy HH:mm:ss z') + '\n' //Fri, 24 May 2013 00:00:00 GMT
                + 'host'.toLowerCase() + ':' + (bucketName + '.s3.amazonaws.com').trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  this.fileContentHash + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n'
                + 'x-amz-storage-class'.toLowerCase() + ':' + 'REDUCED_REDUNDANCY'.trim() + '\n\n'
                + 'date'.toLowerCase() + ';' + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + ';' + 'x-amz-storage-class'.toLowerCase() + '\n'
                +  this.fileContentHash);
        }
    }

    String getServiceCanonicalRequest {
        get {
            return ('GET' + '\n'
                + '/' + '\n\n'
                + 'host'.toLowerCase() + ':' + 's3.amazonaws.com'.trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  emptyStringHash + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n\n'
                + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + '\n'
                + emptyStringHash);
        }
    }

    String getBucketCanonicalRequest {
        get {
            return ('GET' + '\n'
                + '/' + '\n'
                + EncodingUtil.urlEncode('max-keys', 'UTF-8') + '=' + EncodingUtil.urlEncode('2', 'UTF-8')
                + '&' + EncodingUtil.urlEncode('prefix', 'UTF-8') + '=' + EncodingUtil.urlEncode('J', 'UTF-8')  + '\n'
                + 'host'.toLowerCase() + ':' + (bucketName + '.s3.amazonaws.com').trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  emptyStringHash + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n\n'
                + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + '\n'
                +  emptyStringHash);
        }
    }

    private String getCanonicalRequest(sfl.AmazonS3ServiceOperations operation) {
        if (operation == sfl.AmazonS3ServiceOperations.getService) {
            return getServiceCanonicalRequest;
        } else if (operation == sfl.AmazonS3ServiceOperations.getBucket) {
            return getBucketCanonicalRequest;
        } else if (operation == sfl.AmazonS3ServiceOperations.putObject) {
            return putObjectCanonicalRequest;
        }
        return null;
    }

    private Map<AmazonS3ServiceOperations, String> signedHeaderByOperationName = new Map<AmazonS3ServiceOperations, String> {
        sfl.AmazonS3ServiceOperations.getService
            => ',SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=',
        sfl.AmazonS3ServiceOperations.getBucket
            => ',SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=',
        sfl.AmazonS3ServiceOperations.putObject
            => ',SignedHeaders=date;host;x-amz-content-sha256;x-amz-date;x-amz-storage-class,Signature='
    };



/*    // Canonical request
    private Map<AmazonS3ServiceOperations, String> canonicalRequestByOperationName = new Map<AmazonS3ServiceOperations, String> {
        // Operations on Service
        sfl.AmazonS3ServiceOperations.getService
            => ('GET' + '\n'
                + '/' + '\n\n'
                + 'host'.toLowerCase() + ':' + 's3.amazonaws.com'.trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  emptyStringHash + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n\n'
                + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + '\n'
                + emptyStringHash),
        // Operations on Buckets
        AmazonS3ServiceOperations.getBucket
            => ('GET' + '\n'
                + '/' + '\n'
                + EncodingUtil.urlEncode('max-keys', 'UTF-8') + '=' + EncodingUtil.urlEncode('2', 'UTF-8')
                + '&' + EncodingUtil.urlEncode('prefix', 'UTF-8') + '=' + EncodingUtil.urlEncode('J', 'UTF-8')  + '\n'
                + 'host'.toLowerCase() + ':' + (bucketName + '.s3.amazonaws.com').trim() + '\n'
                + 'x-amz-content-sha256'.toLowerCase() + ':' +  emptyStringHash + '\n'
                + 'x-amz-date'.toLowerCase() + ':' + dtKey + '\n\n'
                + 'host'.toLowerCase() + ';' + 'x-amz-content-sha256'.toLowerCase() + ';' + 'x-amz-date'.toLowerCase() + '\n'
                +  emptyStringHash),
        // Operations on Objects
        sfl.AmazonS3ServiceOperations.putObject
            => putObjectCanonicalRequest
    };*/

    public AmazonS3Connector(String IAMUserName) {
        currentUserCreds = [SELECT Id, Name, sfl__Access_Key_Id__c, sfl__Secret_Access_Key__c FROM sfl__AWS_IAM_UserCredintials__c WHERE Name =: IAMUserName];
        System.debug(LoggingLevel.INFO, 'AmazonS3Connector has been constructed');
    }

    @testVisible
    private String generateStringToSign(sfl.AmazonS3ServiceOperations operation) {
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
    private String calculateSignature(sfl.AmazonS3ServiceOperations operation) {
        // Task 3: Calculate Signature
        //signing key = HMAC-SHA256(HMAC-SHA256(HMAC-SHA256(HMAC-SHA256("AWS4" + "<YourSecretAccessKey>","20130524"),"us-east-1"),"s3"),"aws4_request")
        System.debug('\n-------------------------------  Task 3: Calculate Signature --------------------------------');
        Blob dateKey1             = Crypto.generateMac('hmacSHA256', blob.valueOf(dateKey), blob.valueOf('AWS4' + this.currentUserCreds.sfl__Secret_Access_Key__c));
        Blob dateRegionKey        = Crypto.generateMac('hmacSHA256', blob.valueOf(region), dateKey1);
        Blob dateRegionServiceKey = Crypto.generateMac('hmacSHA256', blob.valueOf('s3'), dateRegionKey);
        Blob signingKey           = Crypto.generateMac('hmacSHA256', blob.valueOf('aws4_request'), dateRegionServiceKey);

        String signature = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', blob.valueOf(generateStringToSign(operation)), signingKey));
        System.debug('\n Signature ==> ' + signature);
        return signature;
    }


    @testVisible
    private String calculateAuthorizationHeader(sfl.AmazonS3ServiceOperations operation) {
        String fullAuthHeader = 'AWS4-HMAC-SHA256 Credential=' + this.currentUserCreds.sfl__Access_Key_Id__c + '/' + scope
                                + signedHeaderByOperationName.get(operation) + calculateSignature(operation);
        System.debug('\nfullAuthHeader ' + fullAuthHeader);
        return fullAuthHeader;
    }





//==========================================================================================================================================
//==========================================================================================================================================

    public HttpResponse getService() {
        // Set request's specific variable
        this.region = 'us-east-1';
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(this.protocol + 's3.amazonaws.com');
        req.setHeader('Host', 's3.amazonaws.com');
        req.setHeader('Authorization', calculateAuthorizationHeader(sfl.AmazonS3ServiceOperations.getService));
        req.setHeader('x-amz-date', dtKey);
        req.setHeader('x-amz-content-sha256', emptyStringHash);
        System.debug('\n\n request:\n' + req + '\n\n');
        return performHttpRequest(req);
    }

    public HttpResponse getBucket(String bucketName1) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(this.protocol + bucketName1 + '.s3.amazonaws.com' + '/?max-keys=2&prefix=J');
        req.setHeader('Host', bucketName1 + '.s3.amazonaws.com');
        req.setHeader('Authorization', calculateAuthorizationHeader(sfl.AmazonS3ServiceOperations.getBucket));
        req.setHeader('x-amz-date', dtKey);
        req.setHeader('x-amz-content-sha256', emptyStringHash);
        System.debug('\n\n request:\n' + req + '\n\n');
        return performHttpRequest(req);
    }

    public HttpResponse putObject(String fName, String bucket, String data) {
        this.fileName = fName;
        this.fileContentHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueof(data)));
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setEndpoint(this.protocol + bucket + '.s3.amazonaws.com' + '/' + this.fileName);
        req.setBodyAsBlob(Blob.valueOf(data));
        req.setHeader('Host', bucket + '.s3.amazonaws.com');
        req.setHeader('date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
        req.setHeader('Content-Type', 'text/plain');
        req.setHeader('Authorization', calculateAuthorizationHeader(sfl.AmazonS3ServiceOperations.putObject));
        req.setHeader('x-amz-date', dtKey);
        req.setHeader('x-amz-content-sha256', fileContentHash);
        req.setHeader('x-amz-storage-class', 'REDUCED_REDUNDANCY');
        return performHttpRequest(req);
    }

    private static HttpResponse performHttpRequest(HttpRequest req) {
        if ( !Test.isRunningTest()) {
            Http h          = new Http();
            // Send the request, and return a response
            HttpResponse res = h.send(req);
            System.debug('\n\nRESPONSE' + res + '\n\n');
            System.debug('\n\n\n' + res.getBody() + '\n\n');
            return res;
        }
        return null;
    }

}