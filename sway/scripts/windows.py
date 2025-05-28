#!/bin/python3
import json
import subprocess
from argparse import ArgumentParser


# Returns a list of all json window objects per workspace
def get_workspace_windows():
    command = "swaymsg -t get_tree"
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    data = json.loads(process.communicate()[0])

    windows = []
    for output in data["nodes"]:
        # The scratchpad (under __i3) is not supported
        if output.get("name") != "__i3" and output.get("type") == "output":
            workspaces = output.get("nodes")
            for ws in workspaces:
                if ws.get("type") == "workspace":
                    windows.append((ws.get("num"), extract_nodes(ws)))
    # windows.sort(key=lambda x: x[0])

    return windows


# extract nodes from a container
def extract_leaf_nodes(container):
    leaves = []
    for node in container.get("nodes"):
        if not len(node.get("nodes")):
            leaves.append(node)
        else:
            leaves.extend(extract_leaf_nodes(node))

    return leaves


# Extracts all windows from a sway workspace json object
def extract_nodes(workspace):
    all_nodes = workspace.get("floating_nodes")
    all_nodes.extend(extract_leaf_nodes(workspace))

    return all_nodes


# Returns an array of all windows
def parse_windows(ws_windows):
    indices, strings = [], []
    for i_ws, ws in enumerate(ws_windows):
        for i_w, w in enumerate(ws[1]):
            indices.append((i_ws, i_w))

            # Get app name and window name
            app_name = w.get("app_id") or w.get("window_properties", {}).get(
                "class", "Unknown"
            )
            window_name = w.get("name", "Untitled")

            # Format: "Workspace: App - Window"
            strings.append("<b>{:d}:</b> {} - {}".format(ws[0], app_name, window_name))

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
