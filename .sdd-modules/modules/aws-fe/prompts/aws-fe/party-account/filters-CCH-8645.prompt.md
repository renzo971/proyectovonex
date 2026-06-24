---
agent: neo 
---

## Investigate the swagger-def.yml file.

- Read the swagger-def.yml file to identify the filter taxonomy for the "Technical Addresses" entity.

## Filters 

### Generate a filter for the CsdClients

- Update the url for taxonomy retrieval in the ´TechnicalAddressesList´ component.
- Update the mock for the identified filter taxonomy to include CsdClients. Examples:

  | Value | Label | Column 1 Value | Column 2 Value |
  |-------|-------|----------------|----------------|
  | 1357  | Bayer Corporation | 1357 | Bayer Corporation |
  | 2945  | Adidas Sporting Goods | 2945 | Adidas Sporting Goods |
  | 5791 | BASF Chemical Company | 5791 | BASF Chemical Company |
  | 6832 | Sanofi Pharmaceuticals | 6832 | Sanofi Pharmaceuticals |
  | 9256 | Total Energies | 9256 | Total Energies |

  The columns labels are "CSD Client ID" and "CSD Client Name".

- Update the ´TechnicalAddressesFilters´ component to include filters based on the identified taxonomy, use the ´TableMenuOption[]´ interface for the options attribute. Use a ´TableMultiSelectFilter´ from stratos library for the filter UI component. It should have the ´menuSize´ equal to ´PopoverSize.M´. Use "CSD Client" as label for the button.
- Ensure that the values are remapped in the 
´TechnicalAddressesFilters´ components.
- Ensure that the columns title for the ´TableMultiSelectFilter´ are retrieved from the columns labels in the first element of the taxonomy.

### Generate filter for "Linked to a party"

- Update the mock for the identified filter taxonomy to include "Linked to a party". Examples:

  | Value | Label |
  |-------|-------|
  | YES  | Yes   |
  | NO | No    |

  This filter could be nullable.

- Update the ´TechnicalAddressesFilters´ component to include filters based on the identified taxonomy. Use a ´MultiSelectFilter´ from stratos library for the filter UI component. Use "Linked to a party" as label for the button.

## Use the filters

- Ensure that the filters are applied correctly in the ´TechnicalAddressesList´ component when users interact with them. Do that by passing a ´reloadData´ function to the ´TechnicalAddressesFilters´ component and calling it whenever a filter value changes.
- Ensure that all the filters values are updated correctly when filter component values change using a ´handleChange´ method. 
- Ensure that the ´handleChange´ method updates the filter values in the redux slice using one dispatch call.
- Ensure that the filter values are store in a redux slice. Use the ´TechnicalAddressesSearchModel´ interface to define the filter values structure in the redux slice.
- Ensure that TechnicalAddressesPage uses ´useAppSelector´ to retrieve the filter values from the redux store and passes them to the ´TechnicalAddressesFilters´ component.


### Closed technical addresses filter

- Update the ´TechnicalAddressesFilters´ component to include a ´CheckboxFilter´ from stratos library. The filter is about  showing the "closed technical addresses". It is a boolean value, the property for checked is "value", not "checked". Use "Closed Technical Addresses" as label for the checkbox.

## Clean up

- Remove any unused fields from the ´TechnicalAddressesSearchModel´ and any references to them.

