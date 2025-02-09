# yc resource-manager cloud get <CLOUD_NAME>
variable "yc_cloud_id" {
  type = string
  default = ""
  description = "cloud-id"
}
# yc resource-manager folder get <FOLDER_NAME>
variable "yc_folder_id" {
  type = string
  default = ""
  description = "folder_id"
}

# yc iam service-account create --name <account_name>
variable "yc_sa_account" {
  type = string
  default = ""
  description = "valyan-otus"
}

variable "yc_zone_1a" {
  type = string
  default = "ru-central1-a"
  description = "Зона доступности"
}

# yc iam key create --service-account-name <SERVICE_ACCOUNT_NAME> --output <PATH/TO/KEY/FILE>
variable "yc_sa_key_path" {
  type = string
  default = "/home/valyan/proj/valyan-otus"
  description = "Путь к ключу сервисного аккаунта"
}