
provider "aws"{
    region = "us-east-1"
}

#S3 Bucket
resource "aws_s3_bucket" "website"{
  bucket = "nextjs-portfolio-bucket-jm"
  
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
  
  tags = {
    Name = "Portfolio Website"
    Environment = "Production"
  }
}

# Disable Block Public Access
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access"{
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Ownership Control
resource "aws_s3_bucket_policy" "website_policy"{
  bucket = aws_s3_bucket.website.id

  # This ensures AWS allows public policies before Terraform tries to attach it
  depends_on = [aws_s3_bucket_public_access_block.website_bucket_public_access]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# Cloudfront Distribution
resource "aws_cloudfront_distribution" "website_distribution"{
  origin {
    domain_name = aws_s3_bucket.website.website_endpoint
    origin_id   = "S3-Website"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled             = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "Portfolio CloudFront"
    Environment = "Production"
  }
}