import json
import sys

def process_json_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as json_file:
            json_content = json_file.read()

        valid_json_objects = []

        while json_content:
            try:
                json_object, index = json.JSONDecoder().raw_decode(json_content)
                valid_json_objects.append(json_object)
                json_content = json_content[index:].lstrip()
            except json.JSONDecodeError as e:
                # Handle JSON parsing error by removing the faulty segment
                error_message = str(e)
                start_index = max(0, e.pos - 20)
                end_index = min(len(json_content), e.pos + 20)
                json_content = json_content[:start_index] + json_content[end_index:]

        reformatted_json = json.dumps(valid_json_objects, indent=4, ensure_ascii=False)

        return reformatted_json
    except Exception as e:
        return json.dumps({"error": str(e)})

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Usage: python json_parser.py <json_file_path>"}), file=sys.stderr)
    else:
        json_file_path = sys.argv[1]
        result = process_json_file(json_file_path)
        sys.stdout.buffer.write(result.encode('utf-8'))
