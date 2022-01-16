#!/usr/bin/env python3
from matplotlib import pyplot as plt
import math

def read_file(File, Prec):
    with open(File, 'r') as f:
        data = f.read().split('[')
        intervals = list(map(int, data[1].replace("\n", "").replace("]", "").split(",")))
        values = [v * Prec for v in list(map(float, data[2].replace("\n", "").replace("]", "").split(",")))]
        return intervals, values

def plot_fct(Graph):
    plt.figure(0)
    plt.clf()

    fig, ax1 = plt.subplots()
     

    Factor = 1 if Graph["unit"] == "us" else 0.001 if Graph["unit"] == "ms" else 10000
    
    Values = []
    xaxis = []

    for f in Graph["files"]:
        i,v = read_file("../benchRes/"+ f + ".txt", Factor)
        
        #Apply a transformation tr
        if "tr" in Graph:
            v = [Graph["tr"](vi) for vi in v]
        
        Values.append(v)



        xaxis = [int(x) for x in i]
        ax1.plot(xaxis, v, label=f)
    plt.legend()
    
    if len(Values) == 2:
        ax2 = ax1.twinx()
        factor = [x/y for (y,x) in zip(Values[0], Values[1])]
        ax2.plot(xaxis, factor, label="Ratio", color='g', ls='--')
        ax2.set_ylabel("Ratio between function")
        ax2.set_ylim(ymin=0)

    
    ax1.set_xticks(xaxis)
    plt.title(Graph["title"])
    if "xaxis" in Graph:
        ax1.set_xlabel(Graph["xaxis"])
    else:
        ax1.set_xlabel("Matrix size")
    ax1.set_ylabel("Execution time " + "[" + Graph["unit"] + "]")

    plt.savefig("../benchRes/"+Graph["name"]+".png")

#files: C THEN E!!!! important
Graphs = [
    {"name": "zero_small", "files":["small_zero_c", "small_zero_e"], "unit":"us", "title":"Comparing zero matrix creation"},
    {"name": "zero", "files":["zero_c", "zero_e"], "unit":"ms", "title":"Analysis of time required to create an empty square matrix", "tr": lambda x:x},
    {"name": "plus", "files":["plus_c","plus_e"], "unit":"us", "title":"Comparing '+' operator performances"},
    {"name": "mult_num", "files":["mult_num_c","mult_num_e"], "unit":"us", "title":"Comparing '*(Number, Matrix)' performances"},
    {"name": "mult", "files":["mult_c","mult_e"], "unit":"ms", "title":"Comparing '*(Matrix, Matrix)' performances"},
    {"name": "small mult", "files":["small_mult_c","small_mult_e"], "unit":"ms", "title":"Comparing '*(Matrix, Matrix)' performances for small matrices"},
    {"name": "inv", "files":["inv_c","inv_e"], "unit":"ms", "title":"Comparing matrix inversion performances"},
    {"name": "small inv", "files":["small_inv_c","small_inv_e"], "unit":"ms", "title":"Comparing small matrix inversion performances"},
    {"name": "mult_b", "files":["mult_blas", "mult_nc"], "unit":"ms", "title":"Comparing naïve vs BLAS matrix multiplication"},
    {"name": "solve", "files":["solve_blas", "solve_c"], "unit":"ms", "title":"Comparing solvers"},
    {"name": "tr", "files":["tr_c", "tr_e"], "unit":"ms", "title":"Comparing Transpose"},
    {"name": "emax", "files":["max_c", "max_e"], "unit":"us", "title":"Comparing Max function", "xaxis":"List size"},
    #{"name": "eye", "files":["eye_c", "eye_e"], "unit":"us", "title":"Analysis of time required to create an Identity matrix"},
    #{"name": "max", "files": ["max_list_e", "max_list_c", "max_mat_c"], "unit":"ns", "title":"Nif overhead"},
]

for Graph in Graphs:
    plot_fct(Graph)