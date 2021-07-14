require 'csv'
require 'google/apis/civicinfo_v2'
require "erb"

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
    
  end

  def clean_phone(phone)
    phone = phone.to_str.tr("-","")
    phone.tr!("(", "")
    phone.tr!(")", "")
    phone.tr!(" ", "")
    phone.tr!(".", "")
    
    if phone.length <10 || phone.length > 11
        phone = "0000000000"
    elsif phone.length == 11
        if phone[0]=="1"
            phone = phone[1..phone.length-1]
            
        else 
            phone = "0000000000"
            
        end
        
    
    end
  
  end

  def registration_data_collection(time_string,reg_days_hash,reg_hours_hash)
      #Find out which hours of the day the most people registered

        time_string.gsub!("/0","/200")
      
          reg_day = Date.strptime(time_string,'%m/%e/%Y').wday
              case reg_day
              when 0
                reg_day = "Sunday"
              when 1
                reg_day = "Monday"
              when 2
                reg_day = "Tuesday"
              when 3
                reg_day = "Wednesday"
              when 4
                reg_day = "Thursday"
              when 5
                reg_day = "Friday"
              when 6
                reg_day = "Saturday"
              else
              end
      
              reg_days_hash[reg_day] = reg_days_hash[reg_day].to_i+1
             


            
              reg_hour = time_string[-5..-1][0..1]
              reg_hours_hash[reg_hour]=  reg_hours_hash[reg_hour].to_i+1
              

  end

  def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
    begin
      legislators = civic_info.representative_info_by_address(
        address: zip,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
      ).officials
      legislators = legislators.officials
      legislator_names = legislators.map(&:name)
      legislator_names.join(", ")
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
  end

  def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exist?("output")

    filename = "output/thanks_#{id}.html"

    File.open(filename, "w") do |file|
        file.puts form_letter
    end
    end
  
  puts 'EventManager initialized.'
  reg_days_hash = Hash.new()
  reg_hours_hash = Hash.new()

  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    time_string= row[:regdate]
  

    zipcode = clean_zipcode(row[:zipcode])
  
    phone = clean_phone(row[:homephone])

    registration_data_collection(time_string,reg_days_hash, reg_hours_hash)
  
    legislators = legislators_by_zipcode(zipcode)
  
    form_letter = erb_template.result(binding)

   save_thank_you_letter(id,form_letter)
    
  end
  puts "Registration days and number of registrations are: #{reg_days_hash}"
  puts "Registration hours in a day and number of registrations per hour are: #{reg_hours_hash}"





