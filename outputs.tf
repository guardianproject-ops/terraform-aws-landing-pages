output "bucket_name" {
  value = module.cdn.s3_bucket
}

output "domain_name" {
  value = module.cdn.cf_domain_name
}

output "access_id" {
  value = module.deploy_user.access_key_id
}

output "access_key" {
  value     = module.deploy_user.secret_access_key
  sensitive = "true"
}
