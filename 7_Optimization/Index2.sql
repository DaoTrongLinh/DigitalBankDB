ALTER TABLE customers ADD FULLTEXT idx_ft_customer_info (name, address);
CREATE INDEX idx_comp_trans_source_time ON transactions(account_source_id, time);
CREATE INDEX idx_comp_trans_recv_time ON transactions(account_receiver_id, time);