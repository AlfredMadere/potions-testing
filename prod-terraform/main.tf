terraform {
  cloud {

    organization = "potions-369"

    workspaces {
      name = "potion-infra"
    }
  }
}