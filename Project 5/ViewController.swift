//
//  ViewController.swift
//  Project 5
//
//  Created by Edil Ashimov on 4/20/20.
//  Copyright © 2020 Edil Ashimov. All rights reserved.
//

import UIKit
enum error: Error {
    case notReal
    case notOriginal
    case notPossible
    case isEmpty
    case isIdentical
    case isShort
}

class ViewController: UITableViewController {
    
    var allwords = [String]()
    var userWords = [String]()
    var currentWord: String = ""
    var defaults = UserDefaults.standard
    var jsonDecoder = JSONDecoder()
    var jsonEncoder = JSONEncoder()
    var player = [Player]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        currentWord = allwords.randomElement() ?? "None"
        player = [Player(name: "Unknown", allEntries: userWords, currentWord: currentWord)]
        
        if let savedData = defaults.object(forKey: "Player") as? Data {
            
            if let decodedPeople = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedData) as? Data {
                do {
                    try player = jsonDecoder.decode([Player].self, from: decodedPeople)
                    savePlayerInfo(player)
                    title = player[0].currentWord
                    userWords = player[0].allEntries
                    importWords()
                } catch {
                    print("Failed To Encode")
                }
            }
        } else {
            importWords()
            startGame()
            
        }
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))
        
        
    }
    
    func importWords()  {
        if let startWordURL = Bundle.main.url(forResource: "start", withExtension: "txt"){
            if let startWords =  try? String(contentsOf: startWordURL){
                allwords = startWords.components(separatedBy: "\n")
                currentWord = allwords.randomElement() ?? "None"
                
            }
        }
        if allwords.isEmpty {
            allwords = ["SilkWorm"]
        }
    }
    
    @objc func startGame() {
        title = currentWord
        userWords.removeAll()
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = userWords[indexPath.row]
        return cell
    }
    
    @objc func promptForAnswer() {
        
        let ac = UIAlertController(title: "Enter Answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String)  {
        let lowercased = answer.lowercased()
        
        if answer == "" {
            showErrorMessages(type: error.isEmpty, word: lowercased)
        } else if answer == title {
            showErrorMessages(type: error.isIdentical, word: lowercased)
        } else if  answer.count < 4 {
            showErrorMessages(type: error.isShort, word: lowercased)
        } else {
            if isPossible(lowercased) {
                if isOriginal(lowercased) {
                    if isReal(lowercased) {
                        userWords.insert(lowercased, at: 0)
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .top)
                        let playerInfo = Player(name: "Unknown", allEntries: userWords, currentWord: currentWord)
                        savePlayerInfo([playerInfo])
                        return
                    } else {
                        showErrorMessages(type: error.notReal, word: lowercased)
                    }
                } else {
                    showErrorMessages(type: error.notOriginal, word: lowercased)
                }
            } else {
                showErrorMessages(type: error.notPossible, word: lowercased)
            }
        }
        
    }
    
    func showErrorMessages(type: error, word: String)  {
        
        let errorTitle: String
        let errorMessage: String
        
        switch type {
        case error.notReal:
            errorTitle = "Ooops, Try Again"
            errorMessage = "Enter word doesn't exist"
        case error.notOriginal:
            errorTitle = "Be More Original"
            errorMessage = "Enter word has aleady been used"
        case error.notPossible:
            errorTitle = "No cheating"
            errorMessage = "You can't make \n\(word.uppercased()) \nout of \n\(title!.uppercased())"
        case error.isEmpty:
            errorTitle = "Ooops, it is empty"
            errorMessage = "Submission is empty"
        case error.isIdentical:
            errorTitle = "Ooops, it is identical"
            errorMessage = "You can't use the identical word"
        case error.isShort:
            errorTitle = "Ooops, it is too short"
            errorMessage = "Words must be more than 3 letters"
        }
        
        
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(ac, animated: true)
    }
    
    func isPossible(_ word: String) -> Bool {
        
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter){
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    func isOriginal(_ word: String) -> Bool {
        
        return !userWords.contains(word)
    }
    
    func isReal(_ word: String) -> Bool {
        
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func getDocumentaryDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func savePlayerInfo(_ info: [Player]) {
        
        if let encodedData = try? jsonEncoder.encode(info) {
            let dataToSave = try? NSKeyedArchiver.archivedData(withRootObject: encodedData, requiringSecureCoding: false)
            defaults.set(dataToSave, forKey: "Player")
        }
    }
}

