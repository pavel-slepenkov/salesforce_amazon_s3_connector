public class AmazonS3Connector {
    private final String GET_SERVICE_REGION = 'us-east-1';
    private String protocol = 'https://';
    @testVisible
    private AmazonS3AuthorizationFramework auth;

    public AmazonS3Connector(String bucketConnectionName) {
        this.auth = new AmazonS3AuthorizationFramework(bucketConnectionName);
    }

    private static HttpResponse performHttpRequest(HttpRequest req) {
        if ( !Test.isRunningTest()) {
            Http h = new Http();
            // Send the request, and return a response
            HttpResponse res = h.send(req);
            System.debug('\n\nRESPONSE' + res + '\n\n');
            System.debug('\n\n\n' + res.getBody() + '\n\n');
            return res;
        }
        return null;
    }

//==========================================================================================================================================
//==========================================================================================================================================

    public HttpResponse getService() {
        // Set request's specific variable
        this.auth.setRegion(GET_SERVICE_REGION);
        HttpRequest req = new HttpRequest();
        req.setMethod(AmazonS3Constants.HTTP_METHOD_GET);
        req.setEndpoint(this.protocol + 's3.amazonaws.com');
        req.setHeader('Host', 's3.amazonaws.com');
        req.setHeader('Authorization', this.auth.calculateAuthorizationHeader(AmazonS3ServiceOperations.getService));
        req.setHeader('x-amz-date', this.auth.dtKey);
        req.setHeader('x-amz-content-sha256', AmazonS3Constants.EMPTY_STRING_HASH);
        System.debug('\n\n request:\n' + req + '\n\n');
        return performHttpRequest(req);
    }

    public HttpResponse getBucket(String bucketNameParam) {
        HttpRequest req = new HttpRequest();
        req.setMethod(AmazonS3Constants.HTTP_METHOD_GET);
        req.setEndpoint(this.protocol + bucketNameParam + AmazonS3Constants.AMAZON_S3_URL + '/?max-keys=2&prefix=J');
        req.setHeader('Host', bucketNameParam + AmazonS3Constants.AMAZON_S3_URL);
        req.setHeader('Authorization', this.auth.calculateAuthorizationHeader(AmazonS3ServiceOperations.getBucket));
        req.setHeader('x-amz-date', this.auth.dtKey);
        req.setHeader('x-amz-content-sha256', AmazonS3Constants.EMPTY_STRING_HASH);
        System.debug('\n\n request:\n' + req + '\n\n');
        return performHttpRequest(req);
    }


//------------------------------------------------------------------------------------------------------------------------------------------
//          OBJECT OPERATIONS
//------------------------------------------------------------------------------------------------------------------------------------------

    public HttpResponse putObject(String fName, String bucket, String data) {
        this.auth.fileName = fName;
        this.auth.fileContentHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueof(data)));
        HttpRequest req = new HttpRequest();
        req.setMethod(AmazonS3Constants.HTTP_METHOD_PUT);
        req.setEndpoint(this.protocol + bucket + AmazonS3Constants.AMAZON_S3_URL + '/' + this.auth.fileName);
        req.setBodyAsBlob(Blob.valueOf(data));
        req.setHeader('Host', bucket + AmazonS3Constants.AMAZON_S3_URL);
        req.setHeader('date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
        req.setHeader('Content-Type', 'text/plain');
        req.setHeader('Authorization', this.auth.calculateAuthorizationHeader(AmazonS3ServiceOperations.putObject));
        req.setHeader('x-amz-date', this.auth.dtKey);
        req.setHeader('x-amz-content-sha256', this.auth.fileContentHash);
        req.setHeader('x-amz-storage-class', 'REDUCED_REDUNDANCY');
        return performHttpRequest(req);
    }



    /*
        GET /ObjectName HTTP/1.1
        Host: BucketName.s3.amazonaws.com
        Date: date
        Authorization: authorization string (see Authenticating Requests (AWS Signature Version 4))
        Range:bytes=byte_range
     */
    public HttpResponse getObject(AWSS3Object s3Object) {
        this.auth.fileName = s3Object.fileName;
        HttpRequest getObjectRequest = new HttpRequest();
        getObjectRequest.setMethod(AmazonS3Constants.HTTP_METHOD_GET);
        getObjectRequest.setEndpoint(s3Object.endpoint);
        getObjectRequest.setHeader('Host', s3Object.host);
        getObjectRequest.setHeader('Date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
        getObjectRequest.setHeader('range', 'bytes=0-');
        getObjectRequest.setHeader('Authorization', this.auth.calculateAuthorizationHeader(AmazonS3ServiceOperations.getObject));
        getObjectRequest.setHeader('x-amz-date', this.auth.dtKey);
        getObjectRequest.setHeader('x-amz-content-sha256', AmazonS3Constants.EMPTY_STRING_HASH);
        return performHttpRequest(getObjectRequest);
    }




}