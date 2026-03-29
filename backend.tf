terraform {
  backend "s3" {
    bucket       = "tf-state-lab3-krilyshyn-andrian-08"
    key          = "env/dev/var-08.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
