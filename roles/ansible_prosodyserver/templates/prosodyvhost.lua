VirtualHost "{{ item.domain }}"
ssl = {
	key = "{{ prosody_sslbasepath }}/{{ item.domain }}/privkey.pem";
	certificate = "{{ prosody_sslbasepath }}/{{ item.domain }}/fullchain.pem";
	protocol = "tlsv1_2";
	options = { "no_sslv2", "no_sslv3", "no_ticket", "no_compression", "cipher_server_preference", "single_ecdh_use" };
}
