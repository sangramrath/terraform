resource "azurerm_resource_group" "tfdemo-rg" {
    name = "tfdemo-rg"
    location = "Central US"
    tags {
        environment = "training"
        client = "madura coats"
    }
} 

resource "azurerm_virtual_network" "tfdemo-vnet" {
    name = "tfdemovnet"
    location = "Central US"
    resource_group_name = "${azurerm_resource_group.tfdemo-rg.name}"
    address_space = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "tfdemo-vnet-subnet" {
    name = "tfdemovnetsubnet"
    resource_group_name = "${azurerm_resource_group.tfdemo-rg.name}"
    virtual_network_name = "${azurerm_virtual_network.tfdemo-vnet.name}"
    address_prefix = "10.10.0.0/24"
}

resource "azurerm_network_security_group" "tfdemonsg" {
    name = "tfdemonsg"
    resource_group_name = "${azurerm_resource_group.tfdemo-rg.name}"
    location = "Central US"
    security_rule {
        priority = "100"
        name = "rdp"
        protocol = "tcp"
        destination_port_range = "3389"
        direction = "Inbound"
        source_port_range = "*"
        access = "allow"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "tfdemo-vnet-subnet-vnic" {
    name = "tfdemovnetsubnetvnic"
    location = "Central US"
    resource_group_name = "${azurerm_resource_group.tfdemo-rg.name}"
    network_security_group_id = "${azurerm_network_security_group.tfdemonsg.id}"
        ip_configuration {
            name = "tfdemovnic"
            subnet_id = "${azurerm_subnet.tfdemo-vnet-subnet.id}"
            private_ip_address_allocation = "Dynamic"
            public_ip_address_id = "${azurerm_public_ip.tfdemopublicip.id}"
    }
}

resource "azurerm_public_ip" "tfdemopublicip" {
    name = "tfdemopublicip"
    location = "Central US"
    resource_group_name = "${azurerm_resource_group.tfdemo-rg.name}"
    allocation_method = "Dynamic"
}

resource "azurerm_virtual_machine" "tfdemowinvm" {
    name = "tfdemovm"
    resource_group_name = "${azurerm_resource_group.tfdemo-rg.name}"
    location = "Central US"
    network_interface_ids = ["${azurerm_network_interface.tfdemo-vnet-subnet-vnic.id}"]
    vm_size = "Standard_D2_v2"
    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        sku = "2016-Datacenter"
        offer = "WindowsServer"
        version = "latest"
    }
    storage_os_disk {
        name              = "tfdemoosdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    os_profile {
        computer_name = "tfdemovm"
        admin_username = "devopsadmin"
        admin_password = "Passw0rd@1234567"
    }
    os_profile_windows_config {
        enable_automatic_upgrades = false
    }
}
