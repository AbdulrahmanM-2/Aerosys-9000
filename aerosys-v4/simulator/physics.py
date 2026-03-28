
import random

def update(state, control):
    state["pitch"] += control.get("elevator",0) * 0.02
    state["roll"] += control.get("aileron",0) * 0.02
    return state

if __name__ == "__main__":
    state = {"pitch":0,"roll":0}
    control = {"elevator":0.3,"aileron":0.1}
    print(update(state,control))
