require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
  phone  = phone.to_s.delete("^0-9")
  if phone.length >= 10 && phone.length <= 11
    if phone.length == 11
      if phone[0] != "1"
        "Bad Phone Number"
      else
        phone = phone.to_s[1..10]
        phone
      end
    else
      phone.to_s
    end
  else
    "Bad phone number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def best_hour(date_arr)
  freq = Hash.new
  date_arr.each do |time|
    if freq.include?(time.hour)
      freq[time.hour] += 1
    else
      freq[time.hour] = 1
    end
  end
  return freq.max_by{ |key, value| value }[0]
end

def best_day(date_arr)
  freq = Hash.new
  date_arr.each do |time|
    if freq.include?(time.strftime('%A'))
      freq[time.strftime('%A')] += 1
    else
      freq[time.strftime('%A')] = 1
    end
  end
  return freq.max_by{ |key, value| value }[0]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

time_arr = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  date_time = DateTime.strptime(row[:regdate], '%m/%d/%y %k:%M')
  time_arr << date_time

  phone = clean_phone(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

puts "Best hour of the day : #{best_hour(time_arr)}:00 O'clock"
puts "Best day of the week : #{best_day(time_arr)}"