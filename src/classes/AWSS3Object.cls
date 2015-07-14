/**
 *  represents object for loading into specified AWS Bucket
 *
 *  @author Pavel Slepenkov(pavel.slepenkov@gmail.com)
 */
public class AWSS3Object {
    private final String protocol = 'https://';
    public String bucket;
    public String data;
    public String endpoint;
    public String fileContentHash;
    public String fileName;
    public String host;


    public AWSS3Object(String bucket, String fileName, String data) {
        this.fileName        = fileName;
        this.bucket          = bucket;
        this.data            = data;
        this.endpoint        = this.protocol + this.bucket + AmazonS3Constants.AMAZON_S3_URL + '/' + this.fileName;
        this.fileContentHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueof(this.data)));
        this.host            = this.bucket + AmazonS3Constants.AMAZON_S3_URL;
    }


}