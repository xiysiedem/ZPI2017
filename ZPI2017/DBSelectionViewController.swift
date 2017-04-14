//
//  DBSelectionViewController.swift
//  ZPI2017
//
//  Created by Łukasz on 13.04.2017.
//  Copyright © 2017 ZPI. All rights reserved.
//

import UIKit
import MySqlSwiftNative

class DBSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var con = MySQL.Connection()
    var rows: [MySQL.ResultSet]? = nil
    var rowss: MySQL.ResultSet? = nil
    var list = [DataModel]()
    var dbToDelete: Int = -1
    var showSysTable: Bool = true
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var act: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "DB. Sys. ON", style: .plain, target: self, action: #selector(showSystemTable))
        do{
            //prepare query
            let gett = try con.query(q: "SHOW DATABASES")
            //rows to wszystkie wiersze z query
            rows = try gett.readAllRows()
            //rowss to tez wszystkie wiersze z query XDD
            rowss = rows?[0]
            // row to jeden wiersz z query
            var ii:Int = 1
            var cc:Int = 0
            for row in rowss!{
                cc = 0
                for(key,value) in row{
                    list.append(DataModel(k: key, v: value, r: ii, c:cc))
                    cc += 1
                }
                ii += 1
            }
            
        }catch(let e){
            print(e)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParentViewController){
            do{
                try con.close()
                print("mysql closed")
            } catch(let e){
                print(e)
                // todo lepiej to obsluzyc?
            }
        }
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DBSelectionTableViewCell
        cell.db.text = list[indexPath.row].value as! String
        return cell
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return list.count
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.bringSubview(toFront: act)
        startAct()
        DispatchQueue.main.async {
            let destination = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "tableSelection") as! TableSelectionViewController
            let dbName = self.list[indexPath.row].value as! String
            do{
                try self.con.use(dbname: dbName)
                //prepare query
                let gett = try self.con.query(q: "SHOW TABLES")
                //rows to wszystkie wiersze z query
                self.rows = try gett.readAllRows()
                //rowss to tez wszystkie wiersze z query XDD
                if(self.rows?.isEmpty==false){
                    destination.con = self.con
                    destination.dbName = dbName
                    self.navigationController?.pushViewController(destination, animated: true)
                }else{
                    self.showAlert(message: "Wybrana baza danych jest pusta")
                }
                self.stopAct()
            }catch(let e){
                print(e)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete){
            dbToDelete = indexPath.row
            confirm(msg: (list[indexPath.row].value as! String))
        }
    }
    func confirm(msg: String){
        let alert = UIAlertController(title: "UWAGA", message: "Czy na pewno chcesz usunąć bazę danych \(msg)? Operacja jest nieodwracalna!", preferredStyle: .actionSheet)
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteDB)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    func handleDeleteDB(alertAction: UIAlertAction){
        self.view.bringSubview(toFront: act)
        startAct()
        DispatchQueue.main.async {
            do{
                let query = "DROP DATABASE " + (self.list[self.dbToDelete].value as! String)
                let _ = try self.con.query(q: query)
                self.list.remove(at: self.dbToDelete)
                self.tableView.reloadData()
            }catch(let e){
                print(e)
            }
            self.stopAct()
        }
    }
    func showSystemTable(sender: UIBarButtonItem){
        let db1 = "information_schema"
        let db2 = "mysql"
        let db3 = "performance_schema"
        let db4 = "sys"
        if(showSysTable){
            showSysTable = false
            for dat in list{
                let tmp = dat.value as! String
                if (tmp==db1 || tmp==db2 || tmp==db3 || tmp==db4){
                    removeObj(datMod: tmp)
                }
            }
            self.navigationItem.rightBarButtonItem?.title = "DB. Sys. OFF"
            tableView.reloadData()
        }else{
            list.append(DataModel(k: "", v: db1, r: 0, c: 0))
            list.append(DataModel(k: "", v: db2, r: 0, c: 0))
            list.append(DataModel(k: "", v: db3, r: 0, c: 0))
            list.append(DataModel(k: "", v: db4, r: 0, c: 0))
            showSysTable = true
            self.navigationItem.rightBarButtonItem?.title = "DB. Sys. ON"
            tableView.reloadData()
        }
    }
    func removeObj(datMod: String){
        var ii:Int = 0
        for dat in list{
            let tmp:String = dat.value as! String
            if(tmp==datMod){
                list.remove(at: ii)
            }
            ii += 1
        }
    }
    func showAlert(message: String){
        let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    func startAct(){
        self.view.superview?.bringSubview(toFront: self.act)
        self.act.startAnimating()
        self.act.isHidden = false
    }
    func stopAct(){
        DispatchQueue.main.async {
            self.act.stopAnimating()
        }
    }
}
