# Amahi Home Server
# Copyright (C) 2007-2011 Amahi
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License v3
# (29 June 2007), as published in the COPYING file.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# file COPYING for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Amahi
# team at http://www.amahi.org/ under "Contact Us."
class Partition
  attr_reader  :fstype,:size, :mountpoint, :used, :available
  attr_accessor :kname
  @@types = {primary: 'primary', logical: 'logical', extended: 'extended'}
  cattr_reader :types
  def initialize partition
    partition.each do |key,value|
      instance_variable_set("@#{key}", value) unless value.nil?
    end
  end

  def disk
    # `@disk` is a Disk object
    # Partition has_one Disk relationship
    @disk ||= get_disk
    return @disk
  end

  def delete
    #TODO: remove fstab entry if disk is permanently mounted
    unmount if mountpoint
    Diskwz.delete_partition self
  end

  def path
    return "/dev/#{@kname}"
  end

  def mount label
    label ||= self.kname
    mount_point = File.join "/var/hda/files/drives/", label
    FileUtils.mkdir_p mount_point unless File.directory?(mount_point)
    Diskwz.mount mount_point, self
  end

  def unmount
    Diskwz.umount self
  end
  
  def format fstype
      Diskwz.format self, fstype
  end

  def format_job params_hash
    Disk.progress = 10
    unmount if mountpoint
    new_fstype = params_hash[:fs_type]
    format new_fstype
    Disk.progress = 40
    return true
  end

  def mount_job params_hash
    Disk.progress = 60    
    mount params_hash['label']
    Disk.progress = 80
  end

  def partition_number
    partition_number_string = self.kname.match(/[0-9]*$/)
    return partition_number_string[0].to_i
  end
  private

  def get_disk
    #Strip partition number
    #puts "@kname = #{@kname}"
    disk_kname = @kname.gsub(/[0-9]/, "")
    #puts "disk_kname = #{disk_kname}"
    disk = Disk.find disk_kname
    return disk
  end
end