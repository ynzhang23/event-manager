require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry-byebug'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  # Standardise number to a string with only numbers
  clean_phone_number = phone_number.gsub(/[()\-,. ]/, '')
  # Return phone number if it is 10 digits long
  if clean_phone_number.length == 10
    return clean_phone_number
  elsif clean_phone_number.length == 11 && clean_phone_number[0] == '1'
    return clean_phone_number[1..10]
  else
    return "Bad number"
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def find_reg_time(registered_time)
  registered_time.split[1].rjust(5, '0')
end

def find_reg_date(registered_time)
  date_array = registered_time.split[0].split('/')
  week_day = Date.new(date_array[1].to_i, date_array[0].to_i, date_array[2].to_i).wday
  Date::DAYNAMES[week_day]
end

def save_thank_you_letter(id, form_letter)
  # Create directory for the output files
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

# Repeat for each individual attendee
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  reg_time = find_reg_time(row[:regdate])
  reg_date = find_reg_date(row[:regdate])

  legislators = legislators_by_zipcode(zipcode)

  # Create the result form_letter from the erb_template we created from the file "template_letter"
  # binding will automatically read the value of name + legislators to be used in the erb
  form_letter = erb_template.result(binding)

  # Output final result as files into a created directory
  # save_thank_you_letter(id, form_letter)
end