import email
import traceback
import difflib
from email.parser import Parser

# Adds headers to the provided message object.
# Returns the updated message object if successful. If any issues occurred with
# retrieving or updating the headers, the original message object is returned.
def add_headers(message, message_path, headers):
    try:
        if headers is None:
            print "Unable to add headers for message [%s]: header object was None." + message_path
            return message

        if len(headers) == 0:
            print "No headers found for message [%s]" + message_path

            return message

        #parsed_message = email.message_from_string(message,  headersonly=True)
        parsed_message = Parser().parsestr(message, True)

        header_keys = []
        for header_key, header_value in headers.iteritems():
            header_keys.append(header_key)
            parsed_message[header_key] = header_value

        # required logging for DelayQueueTest, NonSpamEmailTest,
        # SandstormSasiDelayMRTest, SandstormSasiDelayTest
        print 'Added headers for message'

        return parsed_message.as_string()

    except Exception:
        print "Unable to add headers for message [%s]" + message_path
        traceback.print_exc()
    # return the original message without headers
        return message

if __name__ == "__main__":
    # attempt to add any existing headers to the message
    input_filename = '/Users/narendra.shah/Downloads/pic-signed-attached.MESSAGE.eml_signed.eml'
    output_filename = '/Users/narendra.shah/Downloads/pic-signed-attached.MESSAGE.eml_signed_python.eml'
    message_binary = open(input_filename, 'rb').read()
    ofile = open(output_filename, 'wb')


    headers = {'newheader': '1', 'narendra':'yes'}
    message_binary_with_headers = add_headers(
        message_binary,
        'sqs_message.message_path',
        headers
    )
    print(message_binary_with_headers.index('newheader'))
    diff = difflib.ndiff(message_binary, message_binary_with_headers)
    #print(message_binary_with_headers)

    ofile.write(message_binary_with_headers)


