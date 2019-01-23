//
//  ExtrasShoppingViewController.swift
//

import UIKit
import CPEData
import MBProgressHUD

class ExtrasShoppingViewController: MenuedViewController {

    private var extrasShoppingItemsViewController: ExtrasShoppingItemsViewController? {
        for viewController in self.children {
            if let viewController = viewController as? ExtrasShoppingItemsViewController {
                return viewController
            }

            if let navigationController = viewController as? UINavigationController, let viewController = navigationController.topViewController as? ExtrasShoppingItemsViewController {
                return viewController
            }
        }

        return nil
    }

    private var hud: MBProgressHUD?
    private var didAutoSelectCategory = false
    private var productCategoriesSessionDataTask: URLSessionDataTask?
    private var productListSessionDataTask: URLSessionDataTask?

    deinit {
        if let currentTask = productCategoriesSessionDataTask {
            currentTask.cancel()
            productCategoriesSessionDataTask = nil
        }

        if let currentTask = productListSessionDataTask {
            currentTask.cancel()
            productListSessionDataTask = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        menuSections.append(MenuSection(title: String.localize("label.all")))

        if let productCategories = experience.productCategories {
            populateMenu(withCategories: productCategories)
        } else if let productAPIUtil = CPEXMLSuite.Settings.productAPIUtil {
            _ = productAPIUtil.getProductCategories(completion: { [weak self] (productCategories) in
                DispatchQueue.main.async {
                    if let productCategories = productCategories {
                        self?.experience.productCategories = productCategories
                        self?.populateMenu(withCategories: productCategories)
                    }

                    self?.autoSelectFirstCategory()
                }
            })
        } else {
            menuTableView?.removeFromSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        autoSelectFirstCategory()
    }

    private func populateMenu(withCategories productCategories: [ProductCategory]) {
        for category in productCategories {
            let categoryTitle = category.name
            let categoryValue = String(category.id)
            var categoryChildren: [MenuItem]?

            if let children = (category.childCategories ?? nil) {
                if children.count > 1 {
                    categoryChildren = [MenuItem(title: String.localize("label.all"), value: String(category.id))]
                    for child in children {
                        categoryChildren!.append(MenuItem(title: child.name, value: String(child.id)))
                    }
                }
            }

            menuSections.append(MenuSection(title: categoryTitle, value: categoryValue, items: categoryChildren))
        }

        menuTableView?.reloadData()
    }

    private func autoSelectFirstCategory() {
        if !didAutoSelectCategory {
            if let menuTableView = menuTableView {
                let selectedPath = IndexPath(row: 0, section: 0)
                if menuTableView.cellForRow(at: selectedPath) != nil {
                    menuTableView.selectRow(at: selectedPath, animated: false, scrollPosition: UITableView.ScrollPosition.top)
                    self.tableView(menuTableView, didSelectRowAt: selectedPath)
                    if let menuSection = menuSections.first {
                        if menuSection.isExpandable {
                            let selectedPath = IndexPath(row: 1, section: 0)
                            menuTableView.selectRow(at: selectedPath, animated: false, scrollPosition: UITableView.ScrollPosition.top)
                            self.tableView(menuTableView, didSelectRowAt: selectedPath)
                        }

                        didAutoSelectCategory = true
                    }
                }
            } else {
                selectProducts()
                didAutoSelectCategory = true
            }
        }
    }

    private func selectProducts(categoryID: String? = nil) {
        if let app = experience.app, app.isProductApp, let productAPIUtil = CPEXMLSuite.Settings.productAPIUtil {
            productListSessionDataTask?.cancel()
            DispatchQueue.main.async {
                self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                self.productListSessionDataTask = productAPIUtil.getCategoryProducts(categoryID, completion: { [weak self] (products) in
                    self?.productListSessionDataTask = nil

                    DispatchQueue.main.async {
                        self?.extrasShoppingItemsViewController?.products = products
                        self?.hud?.hide(true)
                    }
                })
            }

            Analytics.log(event: .extrasShopAction, action: .selectCategory, itemId: categoryID)
        } else if let childExperiences = experience.childExperiences {
            var products = [ProductItem]()
            for childExperience in childExperiences {
                if let product = childExperience.product {
                    if let categoryID = categoryID {
                        if let category = product.category, category.id == categoryID {
                            products.append(product)
                        }
                    } else {
                        products.append(product)
                    }
                }
            }

            extrasShoppingItemsViewController?.products = products
            Analytics.log(event: .extrasShopAction, action: .selectCategory, itemId: categoryID, itemName: products.first?.category??.name)
        }
    }

    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        if let cell = tableView.cellForRow(at: indexPath) {
            if let menuSection = (cell as? MenuSectionCell)?.menuSection {
                if !menuSection.isExpandable {
                    selectProducts(categoryID: menuSection.value)
                }
            } else {
                selectProducts(categoryID: (cell as? MenuItemCell)?.menuItem?.value)
            }
        }
    }

}
