#!/bin/python3
import json
import subprocess
from argparse import ArgumentParser


# Get all marks from sway
def get_marks():
    command = "swaymsg -t get_marks"
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    marks_data = process.communicate()[0]
    return json.loads(marks_data) if marks_data else []


# Get the mark for a specific window ID
def get_window_mark(window_id, marks):
    if not marks:
        return None

    # Get window info to check for marks
    command = f"swaymsg -t get_tree"
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    tree_data = json.loads(process.communicate()[0])

    # Find the window with this ID and check its marks
    def find_window_marks(node):
        if node.get("id") == window_id:
            return node.get("marks", [])

        for child in node.get("nodes", []):
            result = find_window_marks(child)
            if result is not None:
                return result

        for child in node.get("floating_nodes", []):
            result = find_window_marks(child)
            if result is not None:
                return result

        return None

    window_marks = find_window_marks(tree_data)
    return window_marks[0] if window_marks else None


# Extract scratchpad windows
def get_scratchpad_windows():
    command = "swaymsg -t get_tree"
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    data = json.loads(process.communicate()[0])

    scratchpad_windows = []
    for output in data["nodes"]:
        if output.get("name") == "__i3":
            for container in output.get("nodes", []):
                if container.get("name") == "__i3_scratch":
                    # Scratchpad windows are in floating_nodes of the scratch workspace
                    scratchpad_windows = container.get("floating_nodes", [])
                    break
            break

    return scratchpad_windows


# Returns a list of all json window objects per workspace
def get_workspace_windows():
    command = "swaymsg -t get_tree"
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    data = json.loads(process.communicate()[0])

    windows = []
    for output in data["nodes"]:
        # Skip scratchpad here, we'll handle it separately
        if output.get("name") != "__i3" and output.get("type") == "output":
            workspaces = output.get("nodes")
            for ws in workspaces:
                if ws.get("type") == "workspace":
                    windows.append((ws.get("num"), extract_nodes(ws)))

    # Add scratchpad windows as a special "workspace"
    scratchpad_windows = get_scratchpad_windows()
    if scratchpad_windows:
        windows.append(("SP", scratchpad_windows))

    # Custom sort: 1, 2, 3, ... then 0, then SP
    def sort_workspaces(ws):
        if ws[0] == "SP":
            return 999  # SP at the very end
        elif ws[0] == 0:
            return 998  # Workspace 0 just before SP
        else:
            return ws[0]  # Regular workspaces in numerical order

    windows.sort(key=sort_workspaces)

    return windows


# extract nodes from a container - updated to handle the tree structure better
def extract_leaf_nodes(container):
    leaves = []
    nodes = container.get("nodes", [])

    for node in nodes:
        # If this node has app_id or window_properties, it's a window
        if node.get("app_id") or node.get("window_properties"):
            leaves.append(node)
        # If it has child nodes, recurse into them
        elif node.get("nodes"):
            leaves.extend(extract_leaf_nodes(node))
        # If it has no children and no app info, it might still be a container we want
        else:
            leaves.append(node)

    return leaves


# Extracts all windows from a sway workspace json object
def extract_nodes(workspace):
    all_nodes = []

    # Get floating nodes (like Telegram in your example)
    floating_nodes = workspace.get("floating_nodes", [])
    all_nodes.extend(floating_nodes)

    # Get regular nodes (extract leaf nodes from containers)
    all_nodes.extend(extract_leaf_nodes(workspace))

    return all_nodes


# Returns an array of all windows in workspace order
def parse_windows(ws_windows):
    indices, strings = [], []
    marks = get_marks()  # Get all marks once

    for i_ws, ws in enumerate(ws_windows):
        for i_w, w in enumerate(ws[1]):
            indices.append((i_ws, i_w))

            # Get app name and window name
            app_name = w.get("app_id") or w.get("window_properties", {}).get(
                "class", "Unknown"
            )
            window_name = w.get("name", "Untitled")

            # Get mark for this window
            window_id = w.get("id")
            mark = get_window_mark(window_id, marks) if window_id else None

            # Format with marker if it exists
            if mark:
                # Format: "Workspace: [marker] App - Window"
                strings.append(
                    "<b>{}</b>: [{}] {} - {}".format(ws[0], mark, app_name, window_name)
                )
            else:
                # Format: "Workspace: App - Window" (no marker)
                strings.append(
                    "<b>{}</b>: {} - {}".format(ws[0], app_name, window_name)
                )

    return indices, strings


# Executes wofi with the given input string
def show_wofi(windows):
    command = "wofi -d -i -m -k /dev/null --hide-scroll"
    process = subprocess.Popen(
        command, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE
    )

    return process.communicate(input=windows)[0]


# Returns the sway window id of the window that was selected by the user inside wofi
def parse_id(indices, strings, ws_windows, selected):
    selected = selected.decode("UTF-8")[:-1]  # Remove new line character
    w_index = strings.index(selected)

    return ws_windows[indices[w_index][0]][1][indices[w_index][1]].get("id")


# Switches the focus to the given id
def switch_window(id):
    command = "swaymsg [con_id={:d}] focus".format(id)

    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.communicate()[0]


# Entry point
if __name__ == "__main__":
    parser = ArgumentParser(description="Wofi based window switcher")
    ws_windows = get_workspace_windows()
    indices, strings = parse_windows(ws_windows)
    wofi_string = "\n".join(strings).encode("UTF-8")
    selected = show_wofi(wofi_string)
    selected_id = parse_id(indices, strings, ws_windows, selected)
    switch_window(selected_id)
