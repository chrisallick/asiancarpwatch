class Config
    @@account_sid = "AC3fd82687f1494464dfabcbb450aa05aa"
    @@auth_token = "2e2353776aaf3fed6106c66e062cfa5e"

	def self.getSID()
		return @@account_sid
	end

	def self.getToken()
		return @@auth_token
	end
end