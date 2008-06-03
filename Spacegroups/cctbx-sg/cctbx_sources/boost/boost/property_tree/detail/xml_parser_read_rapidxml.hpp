// ----------------------------------------------------------------------------
// Copyright (C) 2007 Marcin Kalicinski
//
// Distributed under the Boost Software License, Version 1.0. 
// (See accompanying file LICENSE_1_0.txt or copy at 
// http://www.boost.org/LICENSE_1_0.txt)
//
// For more information, see www.boost.org
// ----------------------------------------------------------------------------
#ifndef BOOST_PROPERTY_TREE_DETAIL_XML_PARSER_READ_RAPIDXML_HPP_INCLUDED
#define BOOST_PROPERTY_TREE_DETAIL_XML_PARSER_READ_RAPIDXML_HPP_INCLUDED

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/detail/xml_parser_error.hpp>
#include <boost/property_tree/detail/xml_parser_flags.hpp>
#include <boost/property_tree/detail/xml_parser_utils.hpp>
#include <boost/property_tree/detail/rapidxml.hpp>

namespace boost { namespace property_tree { namespace xml_parser
{

    template<class Ptree, class Ch>
    void read_xml_node(rapidxml::xml_node<Ch> *node, Ptree &pt, int flags)
    {
        switch (node->type())
        {
            // Element nodes
            case rapidxml::node_element: 
            {
                // Create node
                Ptree &pt_node = pt.push_back(std::make_pair(node->name(), Ptree()))->second;
                
                // Copy attributes
                if (node->first_attribute())
                {
                    Ptree &pt_attr_root = pt_node.push_back(std::make_pair(xmlattr<Ch>(), Ptree()))->second;
                    for (rapidxml::xml_attribute<Ch> *attr = node->first_attribute(); attr; attr = attr->next_attribute())
                    {
                        Ptree &pt_attr = pt_attr_root.push_back(std::make_pair(attr->name(), Ptree()))->second;
                        pt_attr.data() = attr->value();
                    }
                }
                
                // Copy children
                for (rapidxml::xml_node<Ch> *child = node->first_child(); child; child = child->next_sibling())
                    read_xml_node(child, pt_node, flags);
            }
            break;

            // Data nodes
            case rapidxml::node_data:
            {
                if (flags & no_concat_text)
                    pt.push_back(std::make_pair(xmltext<Ch>(), Ptree(node->value())));
                else
                    pt.data() += node->value();
            }
            break;

            // Comment nodes
            case rapidxml::node_comment:
            {
                if (!(flags & no_comments))
                    pt.push_back(std::make_pair(xmlcomment<Ch>(), Ptree(node->value())));
            }
            break;

            default:
                // Skip other node types
                break;
        }
    }

    template<class Ptree>
    void read_xml_internal(std::basic_istream<typename Ptree::key_type::value_type> &stream,
                           Ptree &pt,
                           int flags,
                           const std::string &filename)
    {
        typedef typename Ptree::key_type::value_type Ch;

        // Load data into vector
        stream.unsetf(std::ios::skipws);
        std::vector<Ch> v(std::istreambuf_iterator<Ch>(stream.rdbuf()),
                          std::istreambuf_iterator<Ch>());
        if (!stream.good())
            BOOST_PROPERTY_TREE_THROW(xml_parser_error("read error", filename, 0));
        v.push_back(0); // zero-terminate  

        try
        {
            // Parse using appropriate flags
            using namespace rapidxml;
            xml_document<Ch> doc;
            if (flags & no_comments)
                doc.parse<parse_normalize_whitespace>(&v.front());
            else
                doc.parse<parse_normalize_whitespace | parse_comment_nodes>(&v.front());

            // Create ptree from nodes
            Ptree local;
            for (rapidxml::xml_node<Ch> *child = doc.first_child(); child; child = child->next_sibling())
                read_xml_node(child, local, flags);

            // Swap local and result ptrees
            pt.swap(local);
        }
        catch (rapidxml::parse_error &e)
        {
            long line = static_cast<long>(std::count(&v.front(), e.where<Ch>(), Ch('\n')) + 1);
            BOOST_PROPERTY_TREE_THROW(xml_parser_error(e.what(), filename, line));  
        }
    }

} } }

#endif
