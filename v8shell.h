/*
 *  v8shell.h
 *  c8
 *
 *  Created by Grayson Hansard on 9/3/08.
 *  Copyright 2008 From Concentrate Software. All rights reserved.
 *
 */
#include "v8.h"
#include <cstring>
#include <cstdio>
#include <cstdlib>


void RunShell(v8::Handle<v8::Context> context);
bool ExecuteString(v8::Handle<v8::String> source,
                   v8::Handle<v8::Value> name,
                   bool print_result);
v8::Handle<v8::Value> Print(const v8::Arguments& args);
v8::Handle<v8::Value> Load(const v8::Arguments& args);
v8::Handle<v8::Value> Quit(const v8::Arguments& args);
v8::Handle<v8::Value> Version(const v8::Arguments& args);
v8::Handle<v8::String> ReadFile(const char* name);
void ProcessRuntimeFlags(int argc, char* argv[]);

void setupV8Shell(v8::Handle<v8::ObjectTemplate> global);
int runShell(v8::Handle<v8::ObjectTemplate> global, int argc, const char *argv[]);