#!/usr/bin/env python

'''
@author: Adel Daouzli
'''

import os
import sys

class CompareFiles():
    '''Comparing two binary files'''

    def __init__(self, file1, file2):
        '''Get the files to compare and initialise message, offset and diff list.
        :param file1: a file
        :type file1: string
        :param file2: an other file to compare
        :type file2: string
        '''
        self._buffer_size = 512

        self.message = None
        '''message of diff result: "not found", "size", "content", "identical"'''
        self.offset = None
        '''offset where files start to differ'''
        self.diff_list = []
        '''list of diffs made of tuples: (offset, hex(byte1), hex(byte2))'''
        
        self.file1 = file1
        self.file2 = file2

    def compare(self):
        '''Compare the two files

        :returns: Comparison result: True if similar, False if different.
        Set vars offset and message if there's a difference.

        '''
        self.message = None
        self.offset_differs = None
        offset = 0
        offset_diff = 0
        first = False
        if not os.path.isfile(self.file1)or not os.path.isfile(self.file2):
            self.message = "not found"
            return False
        if os.path.getsize(self.file1) != os.path.getsize(self.file2):
            self.message = "size"
            return False
        result = True
        f1 = open(self.file1,'rb')
        f2 = open(self.file2,'rb')

        loop = True
        while loop:
            buffer1 = f1.read(self._buffer_size)
            buffer2 = f2.read(self._buffer_size)
            if len(buffer1) == 0 or len(buffer2) == 0:
                loop = False
            for e in range(len(zip(buffer1, buffer2))):
                if buffer1[e] != buffer2[e]:
                    if first == False:
                        first = True
                    result = False
                    self.diff_list.append((hex(offset),
                                           hex(ord(buffer1[e])),
                                           hex(ord(buffer2[e]))))

                offset += 1
                if first == False:
                    offset_diff += 1
        f1.close()
        f2.close()

        if result == False:
            self.message = 'content'
            self.offset = hex(offset_diff)
        else:
            self.message = 'identical'

        return result

def help_msg(cmd):
    print ("Compare Binary Files - Adel Daouzli")
    print ("Usage: " + cmd + " [-l] file1 file2")
    print ("option -l will list all differences with offsets.")

if __name__ == '__main__':

    if len(sys.argv) > 2 and len(sys.argv) < 5:
        if len(sys.argv) > 3:
            if sys.argv[1].strip() == '-l':
                ls = True
                f1 = sys.argv[2]
                f2 = sys.argv[3]
            else:
                help_msg(os.path.basename(sys.argv[0]))
                sys.exit()
        else:
            ls = False
            f1 = sys.argv[1]
            f2 = sys.argv[2]
        c = CompareFiles(f1, f2)
        result = c.compare()
        print("Result of comparison: " + c.message)
        if not result and c.message == 'content':
            print("offset differs: " + c.offset)
            if ls:
                print ("List of differences:")
                for o, e1, e2 in c.diff_list:
                    print ("offset %s: %s != %s" % (o, e1, e2))
    else:
        help_msg(os.path.basename(sys.argv[0]))
    
