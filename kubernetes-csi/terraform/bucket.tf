resource "yandex_iam_service_account_static_access_key" "valyan-otus-static-key" {
  service_account_id = var.yc_sa_account
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "otus-bucket-1" {
  access_key            = yandex_iam_service_account_static_access_key.valyan-otus-static-key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.valyan-otus-static-key.secret_key
  bucket                = "otus-bucket-1"
  max_size              = 50179869184
  default_storage_class = "cold"
  anonymous_access_flags {
    read        = true
    list        = true
    config_read = true
  }
}