require 'parseconfig'
require 'net/smtp'

$ar = Array.new()
$count = 1

def send_mail( email, action, fname, fsz, ftype )
	
	msgstr = "From: FILEMON SERVICE <from_mail>
	To: Mixey <"+email+">
	Subject: test message
	Date: Sat, 23 Jun 2001 16:26:43 +0900
	Message-Id: <unique.message.id.string@example.com>

    You have new event in your folder: FILE "+fname+"  WAS "+action+", FILESZ: "+fsz.to_s+" TYPE: "+ftype.to_s+".
    "


	Net::SMTP.start( 'mail.domain', 25, 'mail.domain',
	                 'yourmail', 'yourpass', :login) do |smtp|
	  smtp.send_message msgstr,
	                    'from_mail',
	                    'to_mail'
	  smtp.finish
	end

end

def checkidir( fname )
	str = ''
	if( File.directory?(fname) )
		str = "DIR"
	else
		str = "FILE"
	end

	return str
end

def processfiles( aDir ) 
	totalbytes = 0 
	Dir.foreach( aDir ){ 
		|f| 
		aDir.size
		mypath = "#{aDir}\\#{f}" 
		if File.directory?(mypath) then 
			if f != '.' and f != '..' then 
				$ar<<mypath
				processfiles(mypath)  
			end 
		else 
			$ar<<mypath
		end 
	}  
end

def main
	tmp = Array.new
	while(1)
		my_config = ParseConfig.new( "settings.conf" )

		puts "current itertion is #{$count}"
		processfiles( my_config['path'])
		if( $count == 1 ) then
			tmp.concat( $ar )
		else
			if( $ar.size > tmp.size ) then
				$ar.each do |fn|
					if( !tmp.include?(fn) ) then
						puts "New FILE: '#{fn}' fsz: '#{File.new(fn).size}'"
						send_mail( my_config['email'], "CREATED", fn, File.new(fn).size, checkidir(fn) )
						tmp<<fn
					end
				end
			else
				if( $ar.size < tmp.size ) then
					tmp.each do |dfn|
						if( !$ar.include?(dfn) ) then
							puts "FILE WAS DELETED: '#{dfn}'"
							send_mail( my_config['email'], "DELETED", dfn, 0, 0 )
							tmp.delete( dfn )	
						end
					end
				end
			end
		end
		$ar.clear
		$count += 1
		sleep( my_config['interval'].to_i )
	end

end

main