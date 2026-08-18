# Category & Subcategory Restructure — Stop-N-Shop

## Overview
Complete guide to fix and reorganize product categories for Women and Kids, removing incorrect entries and adding proper subcategories with sample products.

---

## Changes Summary

### ❌ Removed (Incorrect Entries)
- **Men Category**: Dresses, Skirts, Sarees, Lehengas (removed - not valid for Men)

### ✅ Added (Women Category)
7 proper subcategories:
1. **Casual Wear** — T-Shirts, Tops, Jeans, Trousers, Shorts, Casual Dresses
2. **Formal Wear** — Shirts, Blazers & Coats, Trousers, Corporate Wear
3. **Indian & Festive Wear** — Sarees, Salwar Kameez, Lehengas, Ethnic Wear
4. **Innerwear & Sleepwear** — Bras, Briefs, Nightwear, Loungewear
5. **Footwear** — Heels, Flats, Casual Shoes, Boots, Sandals, Sports Shoes
6. **Accessories** — Handbags, Scarves, Jewelry, Belts, Sunglasses
7. **Winterwear** — Sweaters, Cardigans, Jackets, Shawls

### ✅ Added (Kids Category)
5 proper subcategories:
1. **Boys Wear** — T-Shirts, Shirts, Shorts, Jeans, Jackets
2. **Girls Wear** — Dresses, Tops, Skirts, Jumpers, Leggings
3. **Innerwear & Sleepwear** — Vests, Briefs, Nightwear
4. **Footwear** — Casual Shoes, Sports Shoes, Sandals, Boots
5. **Accessories** — Caps, Bags, Belts, Socks, Watches

---

## Sample Products Added

### WOMEN Category

#### 1. Casual Wear (2 products)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Women White Cotton T-Shirt | ₹599 | ₹250 | WTSHIRT001 |
| Women Blue Denim Jeans | ₹1,899 | ₹800 | WJEANS001 |

#### 2. Formal Wear (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Women Black Formal Blazer | ₹3,499 | ₹1,500 | WBLAZER001 |

#### 3. Indian & Festive Wear (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Women Silk Saree Red & Gold | ₹7,499 | ₹3,000 | WSAREE001 |

#### 4. Footwear (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Women Black Casual Shoes | ₹1,699 | ₹700 | WSHOES001 |

#### 5. Accessories (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Women Leather Handbag Brown | ₹2,799 | ₹1,200 | WBAG001 |

#### 6. Winterwear (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Women Wool Cardigan Cream | ₹1,999 | ₹850 | WCARDIGAN001 |

### KIDS Category

#### 1. Boys Wear (2 products)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Kids Boys Blue T-Shirt | ₹349 | ₹150 | KBTSHIRT001 |
| Kids Boys Black Shorts | ₹499 | ₹200 | KBSHORTS001 |

#### 2. Girls Wear (2 products)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Kids Girls Pink Dress | ₹649 | ₹280 | KGDRESS001 |
| Kids Girls White Top | ₹399 | ₹170 | KGTOP001 |

#### 3. Footwear (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Kids Sports Shoes Blue | ₹1,399 | ₹600 | KSHOES001 |

#### 4. Accessories (1 product)
| Product Name | Price | Cost | SKU |
|--------------|-------|------|-----|
| Kids Red Baseball Cap | ₹279 | ₹120 | KCAP001 |

---

## Database Schema

### Category Hierarchy

```
Categories (Main Category)
│
├── SubCategories (Subcategory)
│   │
│   └── ProductSubCategories (Junction Table)
│       │
│       └── Products (Individual Products)
```

### Tables Modified

1. **Categories**
   - No structural changes
   - CategoryId, CategoryName, SlugUrl, BannerUrl

2. **SubCategories**
   - Added 12 new rows (7 Women + 5 Kids)
   - Marked old incorrect entries as IsDeleted = 1
   - CategoryId, SubCategoryId, SubCategoryName, SlugUrl

3. **Products**
   - Added 14 sample products
   - ProductId, ProductName, SellerId, BrandId, CategoryId, SubCategoryId

4. **ProductSubCategories**
   - Junction table links products to subcategories
   - ProductId, SubCategoryId

---

## Execution Steps

### Option 1: Manual SQL Execution

1. Open SQL Server Management Studio (SSMS)
2. Connect to `(localdb)\mssqllocaldb`
3. Select database `ShopNShop_db`
4. Open file: `ShopNStopDB/dbo/StoredProcedures/usp_Seed_CategoryUpdates.sql`
5. Execute the script
6. Verify results in output pane

### Option 2: Command Line Execution

```bash
sqlcmd -S "(localdb)\mssqllocaldb" -d ShopNShop_db -i "ShopNStopDB\dbo\StoredProcedures\usp_Seed_CategoryUpdates.sql"
```

### Option 3: Through Stored Procedure

```sql
EXEC usp_Seed_CategoryUpdates
```

---

## Image URLs for Subcategories

Currently using placeholder images. Replace with actual product images:

```
Women:
- Casual Wear: https://via.placeholder.com/50?text=CasualWear
- Formal Wear: https://via.placeholder.com/50?text=FormalWear
- Indian & Festive Wear: https://via.placeholder.com/50?text=IndianWear
- Innerwear & Sleepwear: https://via.placeholder.com/50?text=Innerwear
- Footwear: https://via.placeholder.com/50?text=Footwear
- Accessories: https://via.placeholder.com/50?text=Accessories
- Winterwear: https://via.placeholder.com/50?text=Winterwear

Kids:
- Boys Wear: https://via.placeholder.com/50?text=BoysWear
- Girls Wear: https://via.placeholder.com/50?text=GirlsWear
- Innerwear & Sleepwear: https://via.placeholder.com/50?text=Innerwear
- Footwear: https://via.placeholder.com/50?text=KidsFootwear
- Accessories: https://via.placeholder.com/50?text=KidsAccessories
```

### Recommended Image Sources

**Free High-Quality Images:**
- Unsplash: https://unsplash.com
- Pexels: https://www.pexels.com
- Pixabay: https://pixabay.com
- Freepik: https://www.freepik.com

**Search Terms:**
- "Women casual wear clothing"
- "Women formal wear blazer"
- "Indian festive saree"
- "Kids boys clothing"
- "Kids girls dress"
- "Sports shoes kids"
- "Leather handbag women"

---

## Verification Queries

After execution, run these to verify:

### Check Women Subcategories
```sql
SELECT SubCategoryId, SubCategoryName, SortOrder, IsFeatured 
FROM SubCategories
WHERE CategoryId = (SELECT CategoryId FROM Categories WHERE CategoryName = 'Women' AND IsDeleted = 0)
AND IsDeleted = 0
ORDER BY SortOrder
```

**Expected Result:**
```
SubCategoryId | SubCategoryName           | SortOrder | IsFeatured
1             | Casual Wear              | 1         | 1
2             | Formal Wear              | 2         | 1
3             | Indian & Festive Wear    | 3         | 1
4             | Innerwear & Sleepwear    | 4         | 0
5             | Footwear                 | 5         | 1
6             | Accessories              | 6         | 1
7             | Winterwear               | 7         | 1
```

### Check Kids Subcategories
```sql
SELECT SubCategoryId, SubCategoryName, SortOrder, IsFeatured 
FROM SubCategories
WHERE CategoryId = (SELECT CategoryId FROM Categories WHERE CategoryName = 'Kids' AND IsDeleted = 0)
AND IsDeleted = 0
ORDER BY SortOrder
```

**Expected Result:**
```
SubCategoryId | SubCategoryName           | SortOrder | IsFeatured
1             | Boys Wear                | 1         | 1
2             | Girls Wear               | 2         | 1
3             | Innerwear & Sleepwear    | 3         | 0
4             | Footwear                 | 4         | 1
5             | Accessories              | 5         | 1
```

### Check Product Count by Category
```sql
SELECT 
    c.CategoryName,
    COUNT(p.ProductId) as ProductCount
FROM Categories c
LEFT JOIN Products p ON c.CategoryId = p.CategoryId AND p.IsDeleted = 0
WHERE c.IsDeleted = 0
GROUP BY c.CategoryName
ORDER BY c.CategoryName
```

**Expected for Women & Kids:**
```
CategoryName | ProductCount
Kids         | 9
Women        | 8
```

---

## Frontend Navigation Structure

The updated categories will display as:

```
WOMEN ▼
├── Casual Wear
├── Formal Wear
├── Indian & Festive Wear
├── Innerwear & Sleepwear
├── Footwear
├── Accessories
└── Winterwear

KIDS ▼
├── Boys Wear
├── Girls Wear
├── Innerwear & Sleepwear
├── Footwear
└── Accessories
```

---

## API Endpoints

Access categories through these endpoints:

### Get All Categories
```
GET /api/catalog/categories
```

### Get Subcategories for Category
```
GET /api/catalog/categories/{categoryId}/subcategories
```

### Get Products by Subcategory
```
GET /api/catalog/subcategories/{subcategoryId}/products
```

### Search by Category
```
GET /api/catalog/products?categoryId={id}&page=1&pageSize=20
```

---

## Data Migration Checklist

- [ ] Backup existing database
- [ ] Execute usp_Seed_CategoryUpdates.sql
- [ ] Run verification queries
- [ ] Check Women category in UI (http://localhost:3003)
- [ ] Check Kids category in UI
- [ ] Verify products load for each subcategory
- [ ] Test filtering by subcategory
- [ ] Test search by category
- [ ] Update category images (replace placeholders)
- [ ] Test on mobile/responsive view
- [ ] Test category navigation
- [ ] Commit changes to git

---

## Rollback Instructions

If needed to rollback:

```sql
-- Restore soft-deleted incorrect entries
UPDATE SubCategories SET IsDeleted = 0
WHERE SubCategoryName IN ('Dresses', 'Skirts', 'Sarees', 'Lehengas')
AND CategoryId = (SELECT CategoryId FROM Categories WHERE CategoryName = 'Men')

-- Remove new products (soft delete)
UPDATE Products SET IsDeleted = 1
WHERE CreatedAt > '2024-05-15' -- Use actual execution date

-- Remove new subcategories (soft delete)
UPDATE SubCategories SET IsDeleted = 1
WHERE CreatedAt > '2024-05-15' -- Use actual execution date
```

---

## Future Enhancements

1. **Add more detail levels**: Create sub-subcategories for better organization
   - Example: Footwear → Women → Formal Shoes, Casual Shoes, Heels
   
2. **Add size/variant attributes**: Link sizes (XS, S, M, L, XL) to subcategories

3. **Add color variants**: Link colors to specific products

4. **Add brand-category filters**: Show only brands available in each category

5. **Add seasonal categories**: Spring, Summer, Fall, Winter collections

6. **Implement breadcrumb navigation**: Home > Category > Subcategory > Product

---

## References

### Related Files
- Database Script: `ShopNStopDB/dbo/StoredProcedures/usp_Seed_CategoryUpdates.sql`
- API Controllers: `api/Controllers/CatalogController.cs`
- Frontend Component: `stopnshop-ui/src/features/catalog/`

### Related Documentation
- TECHNICAL_DOCUMENTATION.md
- api/ARCHITECTURE.md
- stopnshop-ui/ARCHITECTURE.md

---

## Support

For issues or questions:
1. Check verification queries above
2. Review database logs in SSMS
3. Check frontend console for API errors
4. Verify API endpoints returning correct data
5. Check image URLs are accessible

