#!/usr/bin/env ruby

require 'xosd_bar'
require 'xosd'

include XOSD

# BEGIN CONFIG
$brightness_file = '/sys/class/backlight/thinkpad_screen/actual_brightness'
$volume_file = '/proc/acpi/ibm/volume'

$max_brightness = 7
$max_volume = 14

# The colors used when the volume is muted or unmuted.
$colors = {
	'unmuted' => 'green',
	'mute' => 'red',
}
# END CONFIG

class RbTPB
	def initialize
		@volumebar = XosdBar.new
		@volumebar.position=BOTTOM
		@volumebar.vertical_offset=100
		@volumebar.align=CENTER
		@volumebar.font="-*-fixed-*-*-*-*-18-*-*-*-*-*-*-*"
		@volumebar.outline_offset=1
		@volumebar.outline_color='black'

		@brightnessbar = XosdBar.new
		@brightnessbar.position=BOTTOM
		@brightnessbar.vertical_offset=150
		@brightnessbar.align=CENTER
		@brightnessbar.font="-*-fixed-*-*-*-*-18-*-*-*-*-*-*-*"
		@brightnessbar.outline_offset=1
		@brightnessbar.outline_color='black'
		@brightnessbar.color='green'
	end

	def read_volume
		File.open($volume_file).each { |line|
			if /^level:/.match(line)
				return -1 if /unreadable/.match(line)
				md = line.match '(\d*)$'
				level = md.to_a[1].to_i
				return level
			end
		}
		return -1
	end

	def read_mute
		File.open($volume_file).each { |line|
			if /^mute:/.match(line)
				if /off$/.match(line)
					return false
				elsif /on$/.match(line)
					return true
				end
			end
		}
		return false
	end

	def read_brightness
		File.open($brightness_file).each { |line| return line.to_i }
		return -1
	end

	def show_volume (volume,mute)
		if mute
			@volumebar.color=$colors['mute']
			@volumebar.title='Volume (Muted)'
		else
			@volumebar.color=$colors['unmuted']
			@volumebar.title='Volume'
		end
		if volume <= 0
			@volumebar.value = 0
		else
			@volumebar.value=(volume * 100 / $max_volume)
		end
		@volumebar.timeout=2
	end

	def show_brightness (brightness)
		@brightnessbar.title='Brightness'
		if brightness <= 0
			@brightnessbar.value = 0
		else
			@brightnessbar.value=(brightness * 100 / $max_brightness)
		end
		@brightnessbar.timeout=2
	end

	def watch
		old_volume = read_volume
		old_mute = read_mute
		old_brightness = read_brightness

		while true
			volume = read_volume
			mute = read_mute
			brightness = read_brightness

			if volume == -1
				puts "Volume unreadable. Giving it a break..."
				sleep 1
				next
			end
			if volume != old_volume 
				puts "Volume changed. Was #{old_volume}, is now #{volume}"
				show_volume(volume,mute)
			end
			if mute != old_mute
				puts "Mute state changed. Was #{old_mute}, is now #{mute}"
				show_volume(volume,mute)
			end

			if brightness == -5
				puts "Brightness unreadable. Giving it a break..."
				sleep 1
				next
			end
			if brightness != old_brightness
				puts "Brightness changed. Was #{old_brightness}, is now #{brightness}"
				show_brightness(brightness)
			end
			old_volume = volume
			old_mute = mute
			old_brightness = brightness
			sleep 0.5
		end
	end
end


rbtpb = RbTPB.new

rbtpb.watch
