# Copyright 2012-2013 Team 254, 2014 Phoenix Racing. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
# @author nathan.lintz@students.olin.edu
# @author patrick.varin@students.olin.edu
# @author kevin.mcclure@students.olin.edu
#
# Represents a single part or assembly in a project.

class Part < Sequel::Model
	many_to_one :project
	many_to_one :user
	many_to_one :parent_part, :class => self
	one_to_many :child_parts, :key => :parent_part_id, :class => self
	
	PART_TYPES = ["part", "assembly"]

	# The list of possible part statuses. Key: string stored in database, value: what is displayed to the user.
	STATUS_MAP = {	"green"		=> "Green Machine",
					"mill"		=> "Manual Mill",
					"cncmill"	=> "CNC Mill",
					"lathe"		=> "Lathe",
					"cnclathe"	=> "CNC Lathe",
					"welding"	=> "Welding",
					"paint"		=> "Spray Paint",
					"sand"		=> "Sandblast",
					"cncrouter"	=> "CNC Router",
					"waterjet" 	=> "Waterjet",
					"rasp"		=> "Rasp",
					"layup"		=> "Layup",
					"bend"		=> "Bend",
					"thermo"	=> "Thermoform",
					"notch"		=> "Notch",
					"laser"		=> "Laser Cutter",
					"assembly"	=> "Waiting for Assembly",
					"progress"	=> "Assembly in Progress",
					"done"		=> "Done",
					"rework"	=> "Rework"}
	STATUS_MAP.default = "Invalid Status"

	# Mapping of priority integer stored in database to what is displayed to the user.
	PRIORITY_MAP = { 0 => "High", 1 => "Normal", 2 => "Low" }

	# FAB_STEPS_COMPLETED = []
	# FAB_STEPS_REMAINING = []


	# Cration of the part
	def self.create_part(project, type, parent_part, part_number, fab_steps)
		new(:fabsteps_remaining => fab_steps, :part_number => part_number, :project_id => project.id, :type => type,
				:parent_part_id => parent_part.nil? ? 0 : parent_part.id)
	end
	
	#change current status to rework by adding it to the front of remaining steps		
	def rework_part

		list_r = fabsteps_remaining.split(/,/)

		if list_r[0] != "rework"
			list_r.unshift "rework"
		end

		self.fabsteps_remaining = list_r.join(",")
		self.status = "rework"
		save

	end

	def complete_next_step
		list_r = fabsteps_remaining.split(/,/)
		list_c = fabsteps_completed.split(/,/)

		list_c = list_c << list_r.shift

		self.fabsteps_completed = list_c.join(",")
		self.fabsteps_remaining = list_r.join(",")
		self.status = list_r[0]
		save
	end

	def reset_steps
		list_r = fabsteps_remaining.split(/,/)
		list_c = fabsteps_completed.split(/,/)

		list_r.delete "rework"
		list_c.concat list_r

		self.fabsteps_completed = ""
		self.fabsteps_remaining = list_c.join(",")
		self.status = list_c[0]
		save
	end

	def completed_steps
		if fabsteps_completed.nil?
			return ''
		else
			return fabsteps_completed.split(/,/)
		end
	end

	def remaining_steps
		if fabsteps_remaining.nil?
			return ''
		else
			return fabsteps_remaining.split(/,/)
		end
	end

	def full_part_number
		part_number
	end

	def claim(user)
		self.user_id = user.id
		save
	end

	def release(user)
		if user.id == user_id or user.can_administer?
			self.user_id = nil
			save
		end
	end

	def claimed?
		return !user_id.nil?
	end
end
