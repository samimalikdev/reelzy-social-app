const CDN_URL = process.env.CDN_URL || '';
const S3_BUCKET_URL = `https://${process.env.AWS_S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com`;

const convertToCDN = (s3Url) => {
  if (!CDN_URL || !s3Url) return s3Url;
  return s3Url.replace(S3_BUCKET_URL, CDN_URL);
};

module.exports = { convertToCDN };
