//
//  dostuff.h
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#ifndef dostuff_h
#define dostuff_h

int doit(void);
void writeTestFileToMobileDirectory(void);
void listDirectory(char*);
void remountRootfs(task_t tfp0, uint64_t kslide);
void writeTestFileToSpecifiedDirectory(char* filename, char* dirtolist);

#endif /* dostuff_h */
