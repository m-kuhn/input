/***************************************************************************
  qgsquicklayertreemodel.h
  --------------------------------------
  Date                 : Nov 2017
  Copyright            : (C) 2017 by Peter Petrik
  Email                : zilolv at gmail dot com
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/


#ifndef LAYERSMODEL_H
#define LAYERSMODEL_H

#include <QAbstractListModel>
#include <QList>
#include <QSet>

class QgsMapLayer;
class QgsProject;

class LayersModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY( QList<QgsMapLayer*> layers READ layers NOTIFY layersChanged )

  public:
    enum Roles
    {
      Name = Qt::UserRole + 1,
      isVector,
      isReadOnly,
      IconSource,
      VectorLayer
    };
    Q_ENUMS( Roles )

    explicit LayersModel(QgsProject* project, QObject* parent = nullptr );
    ~LayersModel();

    Q_INVOKABLE QVariant data ( const QModelIndex& index, int role ) const override;
    Q_INVOKABLE QModelIndex index( int row ) const;   
    Q_INVOKABLE int rowAccordingName(QString name, int defaultIndex = -1) const;
    Q_INVOKABLE int noOfEditableLayers() const;
    Q_INVOKABLE int firstNonOnlyReadableLayerIndex() const;

    int rowCount(const QModelIndex &parent = QModelIndex()) const;

    QHash<int, QByteArray> roleNames() const override;

    QList<QgsMapLayer*> layers() const;

    int defaultLayerIndex() const;
    void setDefaultLayerIndex(int index);

  signals:
    void layersChanged();
    void defaultLayerIndexChanged();

  public slots:
    void reloadLayers(); //when project file changes, reload all layers, etc.

  private:
    QgsProject* mProject;
    QList<QgsMapLayer*> mLayers; // all layers
};

#endif // LAYERSMODEL_H
