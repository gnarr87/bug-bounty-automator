import llm
import os
import logging

# Configure basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Prerequisites ---
# This script requires the 'llm' library and appropriate plugins/API keys.
# 1. Install llm: pip install llm
# 2. Install model plugin (e.g., for OpenAI): llm install llm-openai
# 3. Set API key:
#    - Environment variable (e.g., OPENAI_API_KEY=your_key)
#    - OR using llm keys set openai your_key
# ---

def read_file_content(file_path, max_lines=50):
    """Reads up to max_lines from a file, returning content or None."""
    if not os.path.exists(file_path):
        logging.warning(f"Recon file not found: {file_path}")
        return None
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = [next(f) for _ in range(max_lines)]
        return "".join(lines).strip()
    except Exception as e:
        logging.error(f"Error reading file {file_path}: {e}")
        return None

def create_recon_summary(recon_dir):
    """Creates a text summary from files in the recon directory."""
    summary_parts = []

    # Define files to include in the summary and their descriptions
    files_to_summarize = {
        "subdomains.txt": "Subdomains",
        "live_hosts.txt": "Live Hosts/URLs",
        "ports_tcp.txt": "Open TCP Ports",
        "web_technologies.json": "Web Technologies Detected"
        # Add more files as needed (e.g., UDP ports, screenshots)
    }

    for filename, description in files_to_summarize.items():
        content = read_file_content(os.path.join(recon_dir, filename))
        if content:
            summary_parts.append(f"--- {description} ---\n{content}\n")

    if not summary_parts:
        return "No reconnaissance data found or readable."

    return "\n".join(summary_parts)

def get_llm_suggestions(target_name, recon_dir, model_name, prompt_template):
    """Generates LLM suggestions based on recon data."""
    logging.info(f"Starting LLM analysis for target: {target_name}")

    recon_summary = create_recon_summary(recon_dir)
    if recon_summary == "No reconnaissance data found or readable.":
        logging.warning(f"Skipping LLM analysis for {target_name} due to missing recon data.")
        return None

    # Format the prompt
    try:
        prompt = prompt_template.format(target=target_name, summary=recon_summary)
    except KeyError as e:
        logging.error(f"Error formatting prompt template. Missing key: {e}")
        return None

    logging.info(f"Querying LLM model: {model_name}")
    try:
        # Ensure the model is available
        model = llm.get_model(model_name) # Throws ModelError if not found/configured
        response = model.prompt(prompt)
        # Assuming response object has a 'text' attribute or similar
        suggestions = response.text()
        logging.info(f"Received LLM suggestions for {target_name}")
        return suggestions.strip()
    except ImportError:
         logging.error(f"LLM plugin for model '{model_name}' likely not installed. Try 'llm install ...'")
         return None
    except Exception as e:
        # Catching generic Exception, could be API key issues, network errors, etc.
        logging.error(f"Error querying LLM model '{model_name}': {e}")
        return None

if __name__ == '__main__':
    # Example Usage (requires dummy files and llm setup)
    print("LLM Analyzer Utility")
    print("Note: This example requires the 'llm' library, plugins, API keys,")
    print("and dummy recon files in '../results_test/example_com/recon/' to run.")

    # --- Dummy Setup (for testing) ---
    test_target = "example.com"
    test_base_dir = "../results_test"
    test_target_dir = os.path.join(test_base_dir, test_target)
    test_recon_dir = os.path.join(test_target_dir, "recon")
    test_analysis_dir = os.path.join(test_target_dir, "analysis")

    os.makedirs(test_recon_dir, exist_ok=True)
    os.makedirs(test_analysis_dir, exist_ok=True)

    # Create dummy recon files
    dummy_files = {
        "subdomains.txt": "test.example.com\napi.example.com",
        "live_hosts.txt": "http://example.com\nhttps://test.example.com",
        "ports_tcp.txt": "80/tcp open http\n443/tcp open https\n22/tcp open ssh",
        "web_technologies.json": '[{"url": "http://example.com", "name": "Nginx", "version": "1.18.0"}]'
    }
    for fname, content in dummy_files.items():
        with open(os.path.join(test_recon_dir, fname), "w") as f:
            f.write(content)
    # --- End Dummy Setup ---

    # Configuration (normally loaded from main script/config file)
    test_model = "gpt-3.5-turbo" # CHANGE IF NEEDED & CONFIGURED
    test_prompt = """
Based on the following reconnaissance summary for target '{target}':
---
{summary}
---
Suggest top 3 potential vulnerabilities.
"""

    print(f"\nAttempting analysis for: {test_target}")
    suggestions = get_llm_suggestions(test_target, test_recon_dir, test_model, test_prompt)

    if suggestions:
        print("\n--- LLM Suggestions ---")
        print(suggestions)
        # Save suggestions
        output_path = os.path.join(test_analysis_dir, "llm_suggestions.txt")
        try:
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(suggestions)
            print(f"\nSuggestions saved to: {output_path}")
        except Exception as e:
            print(f"Error saving suggestions: {e}")
    else:
        print("\nFailed to get LLM suggestions. Check logs and LLM configuration.")

    # Clean up dummy files/dirs
    # import shutil
    # if os.path.exists(test_base_dir):
    #     shutil.rmtree(test_base_dir)
