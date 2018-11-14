//
//  ViewController.swift
//  DiffTranslations
//
//  Created by Ronaldo Albertini on 25/10/18.
//  Copyright © 2018 Ronaldo Albertini. All rights reserved.
//

import Cocoa

enum file {
    case first
    case second
}

class ViewController: NSViewController {

    @IBOutlet weak var txtLeft: NSTextField!
    @IBOutlet weak var txtRight: NSTextField!
    
    @IBOutlet weak var btnLeft: NSButton!
    @IBOutlet weak var btnRight: NSButton!
    
    var firstfileKeys: [String] = []
    var secondFileKeys: [String] = []
    var missingLines: [String] = []
    
    var selectedFile:file = .first
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func browseFile(sender: NSButton) {
        
        if sender == self.btnLeft {
            
            self.selectedFile = .first
            self.readFileTo()
        } else if sender == self.btnRight {
            
            self.selectedFile = .second
            self.readFileTo()
        }
    }
    
    func readFileTo() {
        
        let dialog = NSOpenPanel();
        
        dialog.title                  = "Choose a .string file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["strings"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                
                if self.selectedFile == .first {
                    self.txtLeft.stringValue = path
                } else {
                    self.txtRight.stringValue = path
                }

                self.read(path: path)
                
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    func read(path: String) {
        
        guard let reader = LineReader(path: path) else {
            return; // cannot open file
        }
        
        if self.selectedFile == .first {
            firstfileKeys.removeAll()
        } else if self.selectedFile == .second {
            secondFileKeys.removeAll()
        }
        
        for line in reader {
   
            let l:String = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if l.contains("=") {
                if let key:String = l.components(separatedBy: "=").first {
                    
                    if self.selectedFile == .first {
                        self.firstfileKeys.append(key)
                    } else {
                        self.secondFileKeys.append(key)
                    }
                }
            }
        }
    }
    
    @IBAction func toggleInputs(sender:NSButton) {
        
        let aux:String = self.txtLeft.stringValue
        self.txtLeft.stringValue = self.txtRight.stringValue
        self.txtRight.stringValue = aux
        
        self.missingLines.removeAll()
        self.selectedFile = .first
        self.read(path: self.txtLeft.stringValue)
        self.selectedFile = .second
        self.read(path: self.txtRight.stringValue)
    }
    
    @IBAction func checkAction(sender: NSButton) {
        
        self.generateMissingLines()
    }
    
    
    func generateMissingLines() {
        
        let missingKeys =  firstfileKeys.filter { !secondFileKeys.contains($0) }
        
        guard let reader = LineReader(path: self.txtLeft.stringValue) else {
            return; // cannot open file
        }
        
        for line in reader {
            
            let l:String = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if l.contains("=") {
                if let key:String = l.components(separatedBy: "=").first {
                    
                    if missingKeys.contains(key) {
                        self.missingLines.append(l)
                    }
                }
            }
        }
        for item in missingLines {
            print(item)
        }
    }
}



/// Read text file line by line
public class LineReader {
    public let path: String
    
    fileprivate let file: UnsafeMutablePointer<FILE>!
    
    init?(path: String) {
        self.path = path
        file = fopen(path, "r")
        guard file != nil else { return nil }
    }
    
    public var nextLine: String? {
        var line:UnsafeMutablePointer<CChar>? = nil
        var linecap:Int = 0
        defer { free(line) }
        return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
    }
    
    deinit {
        fclose(file)
    }
}

extension LineReader: Sequence {
    public func  makeIterator() -> AnyIterator<String> {
        return AnyIterator<String> {
            return self.nextLine
        }
    }
}

