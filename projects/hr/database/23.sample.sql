UPDATE orgs SET org_name = 'Dew CIS Solutions Ltd', cert_number = 'C.102554', pin = 'P051165288J', vat_number = '0142653A', 
invoice_footer = 'Make all payments to : Dew CIS Solutions ltd
Thank you for your Business
We Turn your information into profitability';

UPDATE transaction_types SET document_number = '10001';

INSERT INTO address (address_id, address_name, sys_country_id, table_name, table_id, post_office_box, postal_code, premises, street, town, phone_number, extension, mobile, fax, email, website, is_default, first_password, details) VALUES (1, NULL, 'KE', 'orgs', 0, '45689', '00100', '16th Floor, view park towers', 'Utalii Lane', 'Nairobi', '+254 (20) 2227100/2243097', NULL, '+254 725 819505 or +254 738 819505', NULL, 'accounts@dewcis.com', 'www.dewcis.com', true, NULL, NULL);



